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

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_access" {
  for_each = toset([
    "roles/datacatalog.categoryFineGrainedReader",
    "roles/dataplex.serviceAgent"
  ])
  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"
}

resource "google_dataplex_datascan" "dq_scan" {
  project      = module.project-services.project_id
  location     = var.region
  data_scan_id = "taxi-scan"

  data {
    resource = "//bigquery.googleapis.com/${google_bigquery_table.taxi.id}"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_quality_spec {
    rules {
      column      = "trip_distance"
      dimension   = "VALIDITY"
      name        = "validity"
      description = "Sample rule for valid column values"
      threshold   = 1.0
      range_expectation {
        min_value = 0
        max_value = 500000
      }
    }

    rules {
      dimension   = "VALIDITY"
      name        = "non-empty-table"
      description = "Sample rule for a non-empty table"
      table_condition_expectation {
        sql_expression = "COUNT(*) > 0"
      }
    }
  }

  depends_on = [
    google_project_iam_member.dataplex_access,
    time_sleep.wait_after_bq_job
  ]
}

resource "google_dataplex_datascan" "thelook" {
  project      = module.project-services.project_id
  location     = var.region
  data_scan_id = "thelook"

  data {
    resource = "//storage.googleapis.com/projects/${module.project-services.project_id}/buckets/${google_storage_bucket.thelook_bucket.name}"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_discovery_spec {
    bigqueryPublishingConfig {
      table_type = "BIGLAKE"
      connections = google_bigquery_connection.storage.name
    }
  }
}


resource "google_dataplex_datascan" "ga4" {
  project      = module.project-services.project_id
  location     = var.region
  data_scan_id = "ga4"

  data {
    resource = "//storage.googleapis.com/projects/${module.project-services.project_id}/buckets/${google_storage_bucket.ga4_bucket.name}"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_discovery_spec {
    bigqueryPublishingConfig {
      table_type = "BIGLAKE"
      connections = google_bigquery_connection.storage.name
    }
  }
}

resource "google_dataplex_datascan" "textocr" {
  project      = module.project-services.project_id
  location     = var.region
  data_scan_id = "textocr"

  data {
    resource = "//storage.googleapis.com/projects/${module.project-services.project_id}/buckets/${google_storage_bucket.textocr_bucket.name}"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_discovery_spec {
    bigqueryPublishingConfig {
      table_type = "BIGLAKE"
      connections = google_bigquery_connection.storage.name
    }
  }
}
