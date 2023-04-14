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

resource "google_project_service_identity" "dataplex_sa" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "dataplex.googleapis.com"
  depends_on = [time_sleep.wait_after_all_workflows]
}

resource "google_dataplex_lake" "gcp_primary" {
  location     = var.region
  name         = "gcp-primary-lake"
  description  = "gcp primary lake"
  display_name = "gcp primary lake"

  labels = {
    gcp-lake = "exists"
  }

  project    = module.project-services.project_id
  depends_on = [time_sleep.wait_after_all_workflows]

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
  depends_on   = [time_sleep.wait_after_all_workflows]
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project    = module.project-services.project_id
  role       = "roles/dataplex.serviceAgent"
  member     = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"
  depends_on = [time_sleep.wait_after_all_workflows]
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

  project    = module.project-services.project_id
  depends_on = [time_sleep.wait_after_all_workflows, google_project_iam_member.dataplex_bucket_access]

}
