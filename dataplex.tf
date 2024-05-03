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
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = module.project-services.project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"
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

  depends_on = [
    google_project_iam_member.dataplex_bucket_access
  ]

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

# Assets are listed below. Assets need to wait for data to be copied to be created.

#asset
resource "google_dataplex_asset" "gcp_primary_textocr" {
  name     = "gcp-primary-textocr"
  location = var.region

  lake          = google_dataplex_lake.gcp_primary.name
  dataplex_zone = google_dataplex_zone.gcp_primary_raw.name

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name             = "projects/${module.project-services.project_id}/buckets/${google_storage_bucket.textocr_images_bucket.name}"
    type             = "STORAGE_BUCKET"
    read_access_mode = "MANAGED"
  }

  project    = module.project-services.project_id
  depends_on = [time_sleep.wait_after_copy_data]

}

#asset
resource "google_dataplex_asset" "gcp_primary_ga4_obfuscated_sample_ecommerce" {
  name     = "gcp-primary-ga4-obfuscated-sample-ecommerce"
  location = var.region

  lake          = google_dataplex_lake.gcp_primary.name
  dataplex_zone = google_dataplex_zone.gcp_primary_raw.name

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name             = "projects/${module.project-services.project_id}/buckets/${google_storage_bucket.ga4_images_bucket.name}"
    type             = "STORAGE_BUCKET"
    read_access_mode = "MANAGED"
  }

  project    = module.project-services.project_id
  depends_on = [time_sleep.wait_after_copy_data]

}

#asset
resource "google_dataplex_asset" "gcp_primary_tables" {
  name     = "gcp-primary-tables"
  location = var.region

  lake          = google_dataplex_lake.gcp_primary.name
  dataplex_zone = google_dataplex_zone.gcp_primary_staging.name

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name             = "projects/${module.project-services.project_id}/buckets/${google_storage_bucket.tables_bucket.name}"
    type             = "STORAGE_BUCKET"
    read_access_mode = "MANAGED"
  }

  project    = module.project-services.project_id
  depends_on = [time_sleep.wait_after_copy_data]
}

# Add a wait for Dataplex Discovery.
# Discovery on this data generally takes 6-8 minutes.
resource "time_sleep" "wait_for_dataplex_discovery" {
  depends_on = [
    google_dataplex_asset.gcp_primary_tables,
    google_dataplex_asset.gcp_primary_ga4_obfuscated_sample_ecommerce,
    google_dataplex_asset.gcp_primary_textocr
  ]

  create_duration = "600s"
}

locals {
  datascan_dataset = replace(google_dataplex_zone.gcp_primary_staging.name, "-", "_")
}

resource "google_dataplex_datascan" "dq_scan" {
  location = var.region
  data_scan_id = "thelook-ecommerce-orders"

  data {
    resource = "//bigquery.googleapis.com/projects/${module.project-services.project_id}/datasets/${local.datascan_dataset}/tables/thelook_ecommerce_orders"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_quality_spec {
    rules {
      column = "order_id"
      dimension = "COMPLETENESS"
      name = "non-null"
      description = "Sample rule for non-null column"
      threshold = 1.0
      non_null_expectation {}
    }

    rules {
      column = "user_id"
      dimension = "COMPLETENESS"
      name = "non-null"
      description = "Sample rule for non-null column"
      threshold = 1.0
      non_null_expectation {}
    }

    rules {
      column = "created_at"
      dimension = "COMPLETENESS"
      name = "non-null"
      description = "Sample rule for non-null column"
      threshold = 1.0
      non_null_expectation {}
    }

    rules {
      column = "order_id"
      dimension = "UNIQUENESS"
      name = "unique"
      description = "Sample rule for values in a set"
      uniqueness_expectation {}
    }

    rules {
      column = "status"
      dimension = "VALIDITY"
      name = "one-of-set"
      description = "Sample rule for values in a set"
      ignore_null = false
      set_expectation {
        values = ["Shipped", "Complete", "Processing", "Cancelled", "Returned"]
      }
    }

    rules {
      column = "num_of_item"
      dimension = "VALIDITY"
      name = "range-values"
      description = "Sample rule for values in a range"
      ignore_null = false
      threshold = 0.99
      range_expectation {
        max_value = 1
        strict_max_enabled = false
        strict_min_enabled = false
      }
    }

    rules {
      dimension = "VALIDITY"
      name = "non-empty-table"
      description = "Sample rule for a non-empty table"
      table_condition_expectation {
        sql_expression = "COUNT(*) > 0"
      }
    }
  }
}