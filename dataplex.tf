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
  provider = google-beta
  project  = module.project-services.project_id
  service  = "dataplex.googleapis.com"
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

}

#zone - raw
resource "google_dataplex_zone" "gcp_primary_raw" {
  discovery_spec {
    enabled = true
  }

  lake     = google_dataplex_lake.gcp_primary.name
  location = var.region
  name     = "gcp-primary-raw"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = "RAW"
  description  = "Zone for thelook_ecommerce image data"
  display_name = "images"
  labels       = {}
  project      = module.project-services.project_id
}

#zone - curated, for staging the data
resource "google_dataplex_zone" "gcp_primary_staging" {
  discovery_spec {
    enabled = true
  }

  lake     = google_dataplex_lake.gcp_primary.name
  location = var.region
  name     = "gcp-primary-staging"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = "CURATED"
  description  = "Zone for thelook_ecommerce tabular data"
  display_name = "staging"
  labels       = {}
  project      = module.project-services.project_id
}

#zone - curated, for BI
resource "google_dataplex_zone" "gcp_primary_curated_bi" {
  discovery_spec {
    enabled = true
  }

  lake     = google_dataplex_lake.gcp_primary.name
  location = var.region
  name     = "gcp-primary-curated"

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  type         = "CURATED"
  description  = "Zone for thelook_ecommerce tabular data"
  display_name = "business_intelligence"
  labels       = {}
  project      = module.project-services.project_id
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = module.project-services.project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"
}
