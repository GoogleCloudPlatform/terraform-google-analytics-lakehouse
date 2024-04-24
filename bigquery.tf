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

# Set up BigQuery resources

# # Create the BigQuery dataset
resource "google_bigquery_dataset" "gcp_lakehouse_ds" {
  project                    = module.project-services.project_id
  dataset_id                 = "gcp_lakehouse_ds"
  friendly_name              = "My gcp_lakehouse Dataset"
  description                = "My gcp_lakehouse Dataset with tables"
  location                   = var.region
  labels                     = var.labels
  delete_contents_on_destroy = var.force_destroy
}

# # Create a BigQuery connection for Spark
resource "google_bigquery_connection" "spark" {
  project       = module.project-services.project_id
  connection_id = "spark"
  location      = var.region
  friendly_name = "gcp lakehouse spark connection"
  spark {}
}

# # This grands permissions to the service account of the Spark connection.
resource "google_project_iam_member" "connection_permission_grant" {
  for_each = toset([
    "roles/biglake.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.connectionAdmin",
    "roles/bigquery.jobUser",
    "roles/bigquery.readSessionUser",
    "roles/storage.objectAdmin"
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = format("serviceAccount:%s", google_bigquery_connection.spark.spark[0].service_account_id)
}

locals {
  lakehouse_catalog = "lakehouse_catalog"
}

# # Creates a stored procedure for a spark job to create iceberg tables
resource "google_bigquery_routine" "create_iceberg_tables" {
  project         = module.project-services.project_id
  dataset_id      = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  routine_id      = "create_iceberg_tables"
  routine_type    = "PROCEDURE"
  language        = "PYTHON"
  definition_body = ""
  arguments {
    name      = "lakehouse_catalog"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  arguments {
    name      = "lakehouse_database"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  arguments {
    name      = "bq_dataset"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  spark_options {
    connection      = google_bigquery_connection.spark.name
    runtime_version = "2.1"
    main_file_uri   = "gs://${google_storage_bucket_object.bigquery_file.bucket}/${google_storage_bucket_object.bigquery_file.name}"
    jar_uris        = ["gs://spark-lib/biglake/biglake-catalog-iceberg1.2.0-0.1.0-with-dependencies.jar"]
    properties = {
      "spark.sql.catalog.lakehouse_catalog" : "org.apache.iceberg.spark.SparkCatalog",
      "spark.sql.catalog.lakehouse_catalog.blms_catalog" : local.lakehouse_catalog
      "spark.sql.catalog.lakehouse_catalog.catalog-impl" : "org.apache.iceberg.gcp.biglake.BigLakeCatalog",
      "spark.sql.catalog.lakehouse_catalog.gcp_location" : var.region,
      "spark.sql.catalog.lakehouse_catalog.gcp_project" : var.project_id,
      "spark.sql.catalog.lakehouse_catalog.warehouse" : "${google_storage_bucket.warehouse_bucket.url}/warehouse",
      "spark.jars.packages" : "org.apache.iceberg:iceberg-spark-runtime-3.3_2.13:1.2.1"
    }
  }
}

# # Execute after Dataplex discovery wait

resource "google_bigquery_job" "create_view_ecommerce" {
  job_id = "create_view_ecommerce_${random_id.id.hex}"

  query {
    query = file("${path.module}/src/sql/view_ecommerce.sql")
  }

  depends_on = [time_sleep.wait_for_dataplex_discovery]
}

resource "google_bigquery_job" "create_iceberg_tables" {
  job_id = "create_iceberg_tables_${random_id.id.hex}"

  query {
    query = "call gcp_lakehouse_ds.create_iceberg_tables('${local.lakehouse_catalog}', 'lakehouse_db', '${google_bigquery_dataset.gcp_lakehouse_ds.dataset_id}')"
  }

  depends_on = [time_sleep.wait_for_dataplex_discovery]
}
