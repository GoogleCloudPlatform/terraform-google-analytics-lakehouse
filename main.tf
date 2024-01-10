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

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "14.4.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "artifactregistry.googleapis.com",
    "biglake.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "datacatalog.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
    "notebooks.googleapis.com",
  ]
}

resource "time_sleep" "wait_after_apis_activate" {
  depends_on      = [module.project-services]
  create_duration = "30s"
}

# Set up service accounts fine grain sec.
resource "google_service_account" "marketing_user" {
  project      = module.project-services.project_id
  account_id   = "user-marketing-sa-${random_id.id.hex}"
  display_name = "Service Account for marketing user"
}

# Set up service accounts fine grain sec.
resource "google_service_account" "lake_admin_user" {
  project      = module.project-services.project_id
  account_id   = "user-lake-admin-sa-${random_id.id.hex}"
  display_name = "Service Account for lake admin user"
}

# Set up service accounts fine grain sec.
resource "google_service_account" "data_analyst_user" {
  project      = module.project-services.project_id
  account_id   = "user-analyst-sa-${random_id.id.hex}"
  display_name = "Service Account for  user"
}

#get gcs svc account
data "google_storage_project_service_account" "gcs_account" {
  project = module.project-services.project_id
}

#random id
resource "random_id" "id" {
  byte_length = 4
}

# Set up Storage Buckets

# # Set up the raw storage bucket
resource "google_storage_bucket" "raw_bucket" {
  name                        = "gcp-${var.use_case_short}-raw-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the warehouse storage bucket
resource "google_storage_bucket" "warehouse_bucket" {
  name                        = "gcp-${var.use_case_short}-warehouse-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "provisioning_bucket" {
  name                        = "gcp-${var.use_case_short}-provisioner-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

}

resource "google_storage_bucket" "ga4_images_bucket" {
  name                        = "gcp-${var.use_case_short}-ga4-images-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "textocr_images_bucket" {
  name                        = "gcp-${var.use_case_short}-textocr-images-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "tables_bucket" {
  name                        = "gcp-${var.use_case_short}-tables-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

# Bucket used to store BI data in Dataplex
resource "google_storage_bucket" "dataplex_bucket" {
  name                        = "gcp-${var.use_case_short}-dataplex-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket_object" "pyspark_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/src/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Uploads the post-startup script for the workbench instance.
resource "google_storage_bucket_object" "post_startup_script" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "post_startup.sh"
  source = "${path.module}/src/post_startup.sh"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

resource "google_storage_bucket" "spark-log-directory" {
  name                        = "gcp-${var.use_case_short}-spark-log-directory-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "phs-staging-bucket" {
  name                        = "gcp-${var.use_case_short}-phs-staging-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "phs-temp-bucket" {
  name                        = "gcp-${var.use_case_short}-phs-temp-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "sparkml-model-bucket" {
  name                        = "gcp-${var.use_case_short}-model-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

# Creates a service account specifically for the Workbench instance.
resource "google_service_account" "workbench_service_account" {
  project      = module.project-services.project_id
  account_id   = "workbench-sa-${random_id.id.hex}"
  display_name = "Service Account for Workbench Instance"
}

# Grants necessary roles to the Workbench service account.
resource "google_project_iam_member" "workbench_sa_roles" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/storage.objectAdmin",
    "roles/compute.osAdminLogin",
    "roles/dataproc.admin",
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workbench_service_account.email}"
}

# Provisions a new Workbench instance.
resource "google_workbench_instance" "workbench_instance" {
  name     = "gcp-${var.use_case_short}-workbench-instance-${random_id.id.hex}"
  project  = module.project-services.project_id
  location = "${var.region}-a"

  gce_setup {
    machine_type = "e2-standard-4"

    vm_image {
      project = "cloud-notebooks-managed"
      name    = "workbench-instances-v20231108-py310"
    }

    network_interfaces {
      network  = google_compute_network.default_network.id
      subnet   = google_compute_subnetwork.subnet.id
      nic_type = "GVNIC"
    }

    disable_public_ip = false

    service_accounts {
      email = google_service_account.workbench_service_account.email
    }

    metadata = {
      proxy-mode            = "service_account"
      idle-timeout-seconds  = "10800"
      report-event-health   = "true"
      disable-mixer         = "false"
      post-startup-script   = "gs://${google_storage_bucket.provisioning_bucket.name}/post_startup.sh"
      report-dns-resolution = "true"
    }

    enable_ip_forwarding = true
  }

  depends_on = [
    google_project_iam_member.workbench_sa_roles
  ]
}
