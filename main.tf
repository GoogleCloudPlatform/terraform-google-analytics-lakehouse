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

data "google_project" "project" {
  project_id = var.project_id
}

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "13.0.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "compute.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "datacatalog.googleapis.com",
    "datalineage.googleapis.com",
    "eventarc.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "storage-api.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "cloudfunctions.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "artifactregistry.googleapis.com",
    "metastore.googleapis.com",
    "dataproc.googleapis.com",
    "dataplex.googleapis.com",
	  "datacatalog.googleapis.com"

  ]
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [module.project-services]

  create_duration = "60s"
}
#random id
resource "random_id" "id" {
  byte_length = 4
}


# Set up BigQuery resources
# # Create the BigQuery dataset
resource "google_bigquery_dataset" "gcp_lakehouse_ds" {
  project       = var.project_id
  dataset_id    = "gcp_lakehouse_ds"
  friendly_name = "My gcp_lakehouse Dataset"
  description   = "My gcp_lakehouse Dataset with tables"
  location      = var.region
  labels        = var.labels
  depends_on = [time_sleep.wait_5_seconds]
}

# # Create a BigQuery connection
resource "google_bigquery_connection" "gcp_lakehouse_connection" {
  project       = var.project_id
  connection_id = "gcp_lakehouse_connection"
  location      = var.region
  friendly_name = "gcp lakehouse storage bucket connection"
  cloud_resource {}
  depends_on = [time_sleep.wait_5_seconds]
}


# Create BigQuery external tables
resource "google_bigquery_table" "gcp_tbl_distribution_centers" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_distribution_centers"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/distribution_centers-*.Parquet"]

  }
}

resource "google_bigquery_table" "gcp_tbl_events" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_events"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/events-*.Parquet"]

  }
}

resource "google_bigquery_table" "gcp_tbl_inventory_items" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_inventory_items"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/inventory_items-*.Parquet"]

  }
}

resource "google_bigquery_table" "gcp_tbl_order_items" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_order_items"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/order_items-*.Parquet"]

  }
}

resource "google_bigquery_table" "gcp_tbl_orders" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_orders"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/orders-*.Parquet"]

  }
}

resource "google_bigquery_table" "gcp_tbl_products" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_products"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/products-*.Parquet"]

  }
}
#bq table on top of biglake bucke
resource "google_bigquery_table" "gcp_tbl_users" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_users"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on = [time_sleep.wait_5_seconds]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/users-*.Parquet"]

  }
}

#dataproc metastore
resource "google_dataproc_metastore_service" "gcp_default" {
  service_id = "gcp-default-metastore"
  location   = "us-central1"
  port       = 9080
  project  = var.project_id
  depends_on = [time_sleep.wait_5_seconds]
}

#dataplex
#get dataplex svc acct info
resource "google_project_service_identity" "dataplex_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "dataplex.googleapis.com"
  depends_on = [time_sleep.wait_5_seconds]
}

#lake
resource "google_dataplex_lake" "gcp_primary" {
  location     = var.region
  name         = "gcp-primary-lake"
  description  = "gcp primary lake"
  display_name = "gcp primary lake"

  labels = {
    gcp-lake = "exists"
  }

  project = var.project_id
  depends_on = [time_sleep.wait_5_seconds]
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
  project      = var.project_id
  depends_on = [time_sleep.wait_5_seconds]
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = var.big_lake_bucket_project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"

  depends_on = [time_sleep.wait_5_seconds]
}

#asset
resource "google_dataplex_asset" "gcp_primary_asset" {
  name          = "gcp-primary-asset"
  location      = var.region 

  lake = google_dataplex_lake.gcp_primary.name
  dataplex_zone = google_dataplex_zone.gcp_primary_zone.name

  discovery_spec {
    enabled = true
  }

  resource_spec {
    name = "projects/${var.big_lake_bucket_project_id}/buckets/${var.bucket_name}"
    type = "STORAGE_BUCKET"
  }

  project = var.project_id
  depends_on = [time_sleep.wait_5_seconds, google_project_iam_member.dataplex_bucket_access]
}
