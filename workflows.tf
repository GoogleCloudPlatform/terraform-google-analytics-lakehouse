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
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "workflows.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}
resource "google_service_account" "workflows_sa" {
  project      = module.project-services.project_id
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account"
  depends_on   = [google_project_service_identity.workflows]
}
# Grant the Workflow service account Workflows Admin
resource "google_project_iam_member" "workflow_service_account_invoke_role" {
  project    = module.project-services.project_id
  role       = "roles/workflows.admin"
  member     = "serviceAccount:${google_service_account.workflows_sa.email}"
  depends_on = [google_service_account.workflows_sa]
}

resource "google_project_iam_member" "workflows_sa_bq_data" {
  project = module.project-services.project_id
  role    = "roles/bigquery.dataOwner"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role
  ]
}
resource "google_project_iam_member" "workflows_sa_gcs_admin" {
  project = module.project-services.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_bq_data
  ]
}
resource "google_project_iam_member" "workflows_sa_bq_resource_mgr" {
  project = module.project-services.project_id
  role    = "roles/bigquery.resourceAdmin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_gcs_admin
  ]
}
resource "google_project_iam_member" "workflow_service_account_token_role" {
  project = module.project-services.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_bq_resource_mgr
  ]
}

#give workflows_sa bq data access
resource "google_project_iam_member" "workflows_sa_bq_connection" {
  project = module.project-services.project_id
  role    = "roles/bigquery.connectionAdmin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflow_service_account_token_role
  ]
}
resource "google_project_iam_member" "workflows_sa_bq_read" {
  project = module.project-services.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_bq_connection
  ]
}
resource "google_project_iam_member" "workflows_sa_log_writer" {
  project = module.project-services.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_bq_read
  ]
}

# Grant the Workflow service account Dataproc admin
resource "google_project_iam_member" "workflow_service_account_dataproc_role" {
  project = module.project-services.project_id
  role    = "roles/dataproc.admin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflow_service_account_dataproc_role
  ]
}

# Grant the Workflow service account BQ admin
resource "google_project_iam_member" "workflow_service_account_bqadmin" {
  project = module.project-services.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflow_service_account_dataproc_role
  ]
}
resource "google_project_iam_member" "workflows_sa_svc_acct_user_role" {
  project = module.project-services.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_project_iam_member.workflows_sa_bq_data
  ]
}

resource "google_workflows_workflow" "workflow_bqml" {
  name            = "workflow-bqml-create"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "Create BQML Model"
  service_account = google_service_account.workflows_sa.email
  source_contents = file("${path.module}/assets/yaml/workflow_bqml.yaml")
  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_project_iam_member.workflow_service_account_dataproc_role
  ]
}

resource "google_workflows_workflow" "workflow_bucket_copy" {
  name            = "workflow_bucket_copy"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "Copy data files from public bucket to solution project"
  service_account = google_service_account.workflows_sa.email
  source_contents = file("${path.module}/assets/yaml/bucket_copy.yaml")
  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_project_iam_member.workflow_service_account_dataproc_role
  ]

}
resource "google_workflows_workflow" "workflows_create_gcp_biglake_tables" {
  name            = "workflow-create-gcp-biglake-tables"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "create gcp biglake tables_18"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/assets/yaml/workflow_create_gcp_lakehouse_tables.yaml", {
    data_analyst_user = google_service_account.data_analyst_user.email,
    marketing_user    = google_service_account.marketing_user.email
  })
  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_project_iam_member.workflow_service_account_dataproc_role
  ]

}

resource "google_workflows_workflow" "workflow_create_views_and_others" {
  name            = "workflow_create_views_and_others"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "create gcp biglake tables_18"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/assets/yaml/workflow_create_views_and_others.yaml", {
    data_analyst_user = google_service_account.data_analyst_user.email,
    marketing_user    = google_service_account.marketing_user.email
  })
  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_project_iam_member.workflow_service_account_dataproc_role
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
    warehouse_bucket         = google_storage_bucket.raw_bucket.name,
    temp_bucket              = google_storage_bucket.raw_bucket.name
  })
  depends_on = [
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_project_iam_member.workflow_service_account_dataproc_role
  ]


}


