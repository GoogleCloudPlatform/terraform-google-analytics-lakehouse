resource "google_project_service_identity" "dataplex_sa" {
  provider = google-beta
  project  = module.project-services.project_id
  service  = "dataplex.googleapis.com"
  depends_on = [data.http.call_workflows_bucket_copy_run,
  data.http.call_workflows_create_gcp_biglake_tables_run]
}

resource "google_dataplex_lake" "gcp_primary" {
  location     = var.region
  name         = "gcp-primary-lake"
  description  = "gcp primary lake"
  display_name = "gcp primary lake"

  labels = {
    gcp-lake = "exists"
  }

  project = module.project-services.project_id
  depends_on = [data.http.call_workflows_bucket_copy_run,
  data.http.call_workflows_create_gcp_biglake_tables_run]

}

#zone
resource "google_dataplex_zone" "gcp_primary_zone" {
  discovery_spec {
    enabled = true
  }

  lake     = google_dataplex_lake.gcp_primary.name
  location = var.region
  name     = "gcp-primary-zone"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = "RAW"
  description  = "Zone for thelookecommerce"
  display_name = "Zone 1"
  labels       = {}
  project      = module.project-services.project_id
  depends_on = [data.http.call_workflows_bucket_copy_run,
  data.http.call_workflows_create_gcp_biglake_tables_run]
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = module.project-services.project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"
  depends_on = [data.http.call_workflows_bucket_copy_run,
  data.http.call_workflows_create_gcp_biglake_tables_run]
}

#asset
resource "google_dataplex_asset" "gcp_primary_asset" {
  name     = "gcp-primary-asset"
  location = var.region

  lake          = google_dataplex_lake.gcp_primary.name
  dataplex_zone = google_dataplex_zone.gcp_primary_zone.name

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name = "projects/${module.project-services.project_id}/buckets/${google_storage_bucket.destination_bucket.name}"
    type = "STORAGE_BUCKET"
  }

  project = module.project-services.project_id
  depends_on = [data.http.call_workflows_bucket_copy_run,
  data.http.call_workflows_create_gcp_biglake_tables_run, google_project_iam_member.dataplex_bucket_access]

}
