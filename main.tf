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
  version                     = "13.0.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "artifactregistry.googleapis.com",
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
    "workflows.googleapis.com"
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


resource "google_storage_bucket_object" "pyspark_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/assets/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]

}

#we will use this as a wait and to make sure every other resource in this project has completed.
#we will then make the last four workflow steps dependent on this
resource "time_sleep" "wait_after_all_resources" {
  create_duration = "120s"
  depends_on = [
    module.project-services,
    google_storage_bucket.provisioning_bucket,
    google_project_service_identity.workflows,
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_connection.gcp_lakehouse_connection,
    google_project_iam_member.connectionPermissionGrant,
    google_workflows_workflow.workflows_create_gcp_biglake_tables,
    data.google_storage_project_service_account.gcs_account
  ]
}

#execute workflows
data "google_client_config" "current" {
}

data "http" "call_workflows_bucket_copy_run" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflow_bucket_copy.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    time_sleep.wait_after_all_resources
  ]
}

data "http" "call_workflows_create_gcp_biglake_tables_run" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflows_create_gcp_biglake_tables.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    time_sleep.wait_after_all_resources,
    data.http.call_workflows_bucket_copy_run
  ]
}

data "http" "call_workflows_create_views_and_others" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflow_create_views_and_others.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    time_sleep.wait_after_all_resources,
    data.http.call_workflows_create_gcp_biglake_tables_run
  ]
}

data "http" "call_workflows_create_iceberg_table" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.initial-workflow-pyspark.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    time_sleep.wait_after_all_resources,
    data.http.call_workflows_create_gcp_biglake_tables_run
  ]
}

resource "time_sleep" "wait_after_all_workflows" {
  create_duration = "30s"

  depends_on = [
    data.http.call_workflows_create_iceberg_table,
    data.http.call_workflows_create_views_and_others,
    data.http.call_workflows_create_gcp_biglake_tables_run,
    data.http.call_workflows_bucket_copy_run,
  ]
}
