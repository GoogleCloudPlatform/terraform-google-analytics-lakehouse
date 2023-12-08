/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ICEBERG setup
# Set up networking
resource "google_compute_network" "default_network" {
  project                 = module.project-services.project_id
  name                    = "vpc-${var.use_case_short}"
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "subnet" {
  project                  = module.project-services.project_id
  name                     = "dataproc-subnet"
  ip_cidr_range            = "10.3.0.0/16"
  region                   = var.region
  network                  = google_compute_network.default_network.id
  private_ip_google_access = true
}

# Firewall rule for dataproc cluster
resource "google_compute_firewall" "subnet_firewall_rule" {
  project = module.project-services.project_id
  name    = "dataproc-firewall"
  network = google_compute_network.default_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  source_ranges = ["10.3.0.0/16"]

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}


# Set up Dataproc service account for the Cloud Function to execute as
# # Set up the Dataproc service account
resource "google_service_account" "dataproc_service_account" {
  project      = module.project-services.project_id
  account_id   = "dataproc-sa-${random_id.id.hex}"
  display_name = "Service Account for Dataproc Execution"
}

resource "google_project_iam_member" "dataproc_sa_roles" {
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/bigquery.connectionAdmin",
    "roles/biglake.admin",
    "roles/bigquery.dataOwner",
    "roles/bigquery.user",
    "roles/dataproc.worker",
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"
}

# # Create a BigQuery connection
resource "google_bigquery_connection" "ds_connection" {
  project       = module.project-services.project_id
  connection_id = "gcp_gcs_connection"
  location      = var.region
  friendly_name = "Storage Bucket Connection"
  cloud_resource {}
}

# # Grant IAM access to the BigQuery Connection account for Cloud Storage
resource "google_project_iam_member" "bq_connection_iam_object_viewer" {
  project = module.project-services.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_bigquery_connection.ds_connection.cloud_resource[0].service_account_id}"
}

# # Grant IAM access to the BigQuery Connection account for BigLake Metastore
resource "google_project_iam_member" "bq_connection_iam_biglake" {
  project = module.project-services.project_id
  role    = "roles/biglake.admin"
  member  = "serviceAccount:${google_bigquery_connection.ds_connection.cloud_resource[0].service_account_id}"
}

resource "google_dataproc_cluster" "phs" {
  name    = "gcp-${var.use_case_short}-phs-${random_id.id.hex}"
  project = module.project-services.project_id
  region  = var.region
  cluster_config {
    staging_bucket = google_storage_bucket.phs-staging-bucket.name
    temp_bucket    = google_storage_bucket.phs-temp-bucket.name

    master_config {
      machine_type = "n1-standard-2"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 250
      }
    }
    gce_cluster_config {
      service_account = google_service_account.dataproc_service_account.email
      subnetwork      = google_compute_subnetwork.subnet.name
    }
    software_config {
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
        "spark:spark.history.fs.logDirectory"  = "gs://${google_storage_bucket.spark-log-directory.name}/phs/*/spark-job-history"
      }
    }
    endpoint_config {
      enable_http_port_access = "true"
    }
  }

  depends_on = [
    google_project_iam_member.dataproc_sa_roles
  ]
}
