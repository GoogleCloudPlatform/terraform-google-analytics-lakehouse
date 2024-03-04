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

resource "google_project_service_identity" "workflows" {
  provider = google-beta
  project  = module.project-services.project_id
  service  = "workflows.googleapis.com"

  depends_on = [time_sleep.wait_after_apis_activate]
}

resource "google_service_account" "workflows_sa" {
  project      = module.project-services.project_id
  account_id   = "workflows-sa-${random_id.id.hex}"
  display_name = "Workflows Service Account"

  depends_on = [google_project_service_identity.workflows]
}

resource "google_project_iam_member" "workflows_sa_roles" {
  for_each = toset([
    "roles/workflows.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/dataproc.admin",
    "roles/bigquery.admin",
    "roles/dataplex.admin"
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_service_account.workflows_sa
  ]
}

# Workflow to copy data from prod GCS bucket to private buckets
# NOTE: google_storage_bucket.<bucket>.name omits the `gs://` prefix.
# You can use google_storage_bucket.<bucket>.url to include the prefix.
resource "google_workflows_workflow" "copy_data" {
  name            = "copy-data"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Copies data and performs project setup"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/src/yaml/copy-data.yaml", {
    public_data_bucket    = var.public_data_bucket,
    textocr_images_bucket = google_storage_bucket.textocr_images_bucket.name,
    ga4_images_bucket     = google_storage_bucket.ga4_images_bucket.name,
    tables_bucket         = google_storage_bucket.tables_bucket.name,
    dataplex_bucket       = google_storage_bucket.dataplex_bucket.name,
    images_zone_name      = google_dataplex_zone.gcp_primary_raw.name,
    tables_zone_name      = google_dataplex_zone.gcp_primary_staging.name,
    lake_name             = google_dataplex_lake.gcp_primary.name
  })

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
    google_project_iam_member.dataproc_sa_roles
  ]

}

# Workflow to set up project resources
# Note: google_storage_bucket.<bucket>.name omits the `gs://` prefix.
# You can use google_storage_bucket.<bucket>.url to include the prefix.
resource "google_workflows_workflow" "project_setup" {
  name            = "project-setup"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Copies data and performs project setup"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/src/yaml/project-setup.yaml", {
    bq_dataset                = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
    lakehouse_catalog         = local.lakehouse_catalog
    dataplex_asset_tables_id  = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-staging/assets/gcp-primary-tables"
    dataplex_asset_textocr_id = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-raw/assets/gcp-primary-textocr"
    dataplex_asset_ga4_id     = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-raw/assets/gcp-primary-ga4-obfuscated-sample-ecommerce"
  })
  # Note: using the asset_id values below in project_setup config threw an IAM error when executing.
  # This is likely caused by added delays in IAM propagating and causes the workflow to fail.
  #   dataplex_asset_tables_id  = google_dataplex_asset.gcp_primary_tables.id,
  #   dataplex_asset_textocr_id = google_dataplex_asset.gcp_primary_textocr.id,
  #   dataplex_asset_ga4_id     = google_dataplex_asset.gcp_primary_ga4_obfuscated_sample_ecommerce.id
  # })
  depends_on = [
    google_project_iam_member.workflows_sa_roles,
    google_project_iam_member.dataproc_sa_roles
  ]

}

# execute workflows after all resources are created
# # get a token to execute the workflows
data "google_client_config" "current" {
}

# # execute the copy data workflow
data "http" "call_workflows_copy_data" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.copy_data.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    google_storage_bucket.textocr_images_bucket,
    google_storage_bucket.ga4_images_bucket,
    google_storage_bucket.tables_bucket
  ]
}

resource "time_sleep" "wait_after_copy_data" {
  create_duration = "30s"
  depends_on = [
    data.http.call_workflows_copy_data
  ]
}

# execute the other project setup workflow
data "http" "call_workflows_project_setup" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.project_setup.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_routine.create_iceberg_tables,
    google_bigquery_routine.create_view_ecommerce,
    google_dataplex_asset.gcp_primary_ga4_obfuscated_sample_ecommerce,
    google_dataplex_asset.gcp_primary_tables,
    google_dataplex_asset.gcp_primary_textocr,
    google_project_iam_member.connection_permission_grant,
    google_project_iam_member.dataproc_sa_roles,
    google_service_account.dataproc_service_account,
    google_storage_bucket.provisioning_bucket,
    google_storage_bucket.warehouse_bucket,
    time_sleep.wait_after_copy_data
  ]
}

# Wait for the project setup workflow to finish. This step should take about
# 12 minutes total. Completing this is not a blocker to begin exploring the
# deployment, but we pause for five minutes to give some resources time to
# spin up.
resource "time_sleep" "wait_after_all_workflows" {
  create_duration = "300s"

  depends_on = [
    data.http.call_workflows_project_setup,
  ]
}

# Stop the workbench instnace after creation since it costs too much.
# tflint-ignore: terraform_unused_declarations
data "http" "call_stop_workbench_instance" {
  url    = "https://notebooks.googleapis.com/v2/projects/${module.project-services.project_id}/locations/${var.region}-a/instances/${google_workbench_instance.workbench_instance.name}:stop"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
}
