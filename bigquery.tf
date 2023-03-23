# Set up BigQuery resources
# # Create the BigQuery dataset
resource "google_bigquery_dataset" "gcp_lakehouse_ds" {
  project       = module.project-services.project_id
  dataset_id    = "gcp_lakehouse_ds"
  friendly_name = "My gcp_lakehouse Dataset"
  description   = "My gcp_lakehouse Dataset with tables"
  location      = var.region
  labels        = var.labels
  depends_on    = [time_sleep.wait_after_adding_eventarc_svc_agent]
}



# # Create a BigQuery connection
resource "google_bigquery_connection" "gcp_lakehouse_connection" {
  project       = module.project-services.project_id
  connection_id = "gcp_lakehouse_connection"
  location      = var.region
  friendly_name = "gcp lakehouse storage bucket connection"
  cloud_resource {}
  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent]
}



## This grants permissions to the service account of the connection created in the last step.
resource "google_project_iam_member" "connectionPermissionGrant" {
  project = module.project-services.project_id
  role    = "roles/storage.objectViewer"
  member  = format("serviceAccount:%s", google_bigquery_connection.gcp_lakehouse_connection.cloud_resource[0].service_account_id)
}

resource "google_bigquery_routine" "create_view_ecommerce" {
  project         = module.project-services.project_id
  dataset_id      = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  routine_id      = "create_view_ecommerce"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("${path.module}/assets/sql/view_ecommerce.sql")
}
