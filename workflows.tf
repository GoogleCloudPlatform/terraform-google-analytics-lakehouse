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

#dag order #1
resource "google_project_service_identity" "workflows" {
  provider = google-beta
  project  = module.project-services.project_id
  service  = "workflows.googleapis.com"

  depends_on = [time_sleep.wait_after_apis_activate]
}

resource "google_service_account" "workflows_sa" {
  project      = module.project-services.project_id
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account"

  depends_on = [google_project_service_identity.workflows]
}

resource "google_project_iam_member" "workflows_sa_roles" {
  for_each = toset([
    "roles/workflows.admin",
    "roles/bigquery.dataOwner",
    "roles/storage.admin",
    "roles/bigquery.resourceAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/bigquery.connectionAdmin",
    "roles/bigquery.jobUser",
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

resource "google_workflows_workflow" "workflow_bqml" {
  name            = "initial-workflow-create-model"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Create BQML Model"
  service_account = google_service_account.workflows_sa.email
  source_contents = file("${path.module}/assets/yaml/initial-workflow-create-model.yaml")

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
  ]
}

resource "google_workflows_workflow" "workflow_bucket_copy" {
  name            = "initial-workflow-copy-data"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Copy data files from public bucket to solution project"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/assets/yaml/initial-workflow-copy-data.yaml", {
    raw_bucket = google_storage_bucket.raw_bucket.name
  })

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
  ]

}
resource "google_workflows_workflow" "workflows_create_gcp_biglake_tables" {
  name            = "initial-workflow-create-gcp-biglake-tables"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Runs post Terraform setup steps for Solution in Console"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/assets/yaml/initial-workflow-create-gcp-biglake-tables.yaml", {
    data_analyst_user = google_service_account.data_analyst_user.email,
    marketing_user    = google_service_account.marketing_user.email,
    raw_bucket        = google_storage_bucket.raw_bucket.name,
  })

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
  ]

}


resource "google_workflows_workflow" "initial-workflow-pyspark" {
  name            = "initial-workflow-pyspark"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Runs post Terraform setup steps for Solution in Console"
  service_account = google_service_account.workflows_sa.id
  source_contents = templatefile("${path.module}/assets/yaml/initial-workflow-pyspark.yaml", {
    dataproc_service_account = google_service_account.dataproc_service_account.email,
    provisioner_bucket       = google_storage_bucket.provisioning_bucket.name,
    warehouse_bucket         = google_storage_bucket.warehouse_bucket.name,
    temp_bucket              = google_storage_bucket.warehouse_bucket.name
  })

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
    google_project_iam_member.dataproc_sa_roles,
  ]

}
