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
  version                     = "14.3.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "artifactregistry.googleapis.com",
    "biglake.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
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

resource "google_storage_bucket_object" "pyspark_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/src/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]

}

# Resources are dependent on one another. We will ensure the following set of resources are created before proceeding.
resource "time_sleep" "wait_after_all_resources" {
  create_duration = "120s"
  depends_on = [
    module.project-services,
    google_storage_bucket.provisioning_bucket,
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_connection.gcp_lakehouse_connection,
    google_project_iam_member.connectionPermissionGrant,
    google_workflows_workflow.project_setup,
    google_dataplex_zone.gcp_primary_raw,
    google_dataplex_zone.gcp_primary_staging,
    google_dataplex_zone.gcp_primary_curated_bi,
    data.google_storage_project_service_account.gcs_account,
    data.http.call_workflows_copy_data
  ]
}
