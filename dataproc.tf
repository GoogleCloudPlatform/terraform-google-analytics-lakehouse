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

  depends_on = [
    google_compute_network.default_network,
  ]
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

  depends_on = [
    google_service_account.dataproc_service_account
  ]
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

  depends_on = [
    google_bigquery_connection.ds_connection
  ]
}

# # Grant IAM access to the BigQuery Connection account for BigLake Metastore
resource "google_project_iam_member" "bq_connection_iam_biglake" {
  project = module.project-services.project_id
  role    = "roles/biglake.admin"
  member  = "serviceAccount:${google_bigquery_connection.ds_connection.cloud_resource[0].service_account_id}"

  depends_on = [
    google_bigquery_connection.ds_connection
  ]
}

# # Create a BigQuery external table.
resource "google_bigquery_table" "tbl_thelook_events" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_events"
  project             = module.project-services.project_id
  deletion_protection = var.deletion_protection

  external_data_configuration {
    autodetect    = true
    connection_id = google_bigquery_connection.ds_connection.name #TODO: Change other solutions to remove hardcoded reference
    source_format = "PARQUET"
    source_uris   = ["gs://${var.public_data_bucket}/thelook_ecommerce/events-*.Parquet"]

  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "user_id",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "sequence_number",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "session_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "ip_address",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "postal_code",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "browser",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "traffic_source",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "uri",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "event_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  }
]
EOF

  depends_on = [
    google_bigquery_connection.ds_connection,
    google_storage_bucket.raw_bucket
  ]
}

resource "google_storage_bucket" "spark-log-directory" {
  name                        = "gcp-${var.use_case_short}-spark-log-directory-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_dataproc_cluster" "phs" {
  name    = "gcp-${var.use_case_short}-phs-${random_id.id.hex}"
  project = module.project-services.project_id
  region  = var.region
  cluster_config {
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
}
