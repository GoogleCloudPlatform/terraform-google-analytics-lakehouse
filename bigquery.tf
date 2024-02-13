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
# Create the BigQuery dataset
resource "google_bigquery_dataset" "gcp_lakehouse_ds" {
  project                    = module.project-services.project_id
  dataset_id                 = "gcp_lakehouse_ds"
  friendly_name              = "My gcp_lakehouse Dataset"
  description                = "My gcp_lakehouse Dataset with tables"
  location                   = var.region
  labels                     = var.labels
  delete_contents_on_destroy = var.force_destroy
}

# Create a BigQuery connection for cloud resources
resource "google_bigquery_connection" "gcp_lakehouse_connection_cloud_resource" {
  project       = module.project-services.project_id
  connection_id = "gcp_lakehouse_connection_cloud_resource"
  location      = var.region
  friendly_name = "gcp lakehouse storage bucket connection"
  cloud_resource {}
}

# Create a BigQuery connection for Spark
resource "google_bigquery_connection" "gcp_lakehouse_connection_spark" {
  project       = module.project-services.project_id
  connection_id = "gcp_lakehouse_connection_spark"
  location      = var.region
  friendly_name = "gcp lakehouse spark connection"
  spark {}
}

# This grants permissions to the service account of the Cloud Resource connection.
resource "google_project_iam_member" "connectionPermissionGrantCloudResource" {
  project = module.project-services.project_id
  role    = "roles/storage.objectViewer"
  member  = format("serviceAccount:%s", google_bigquery_connection.gcp_lakehouse_connection_cloud_resource.cloud_resource[0].service_account_id)
}

# This grands permissions to the service account of the Spark connection.
resource "google_project_iam_member" "connectionPermissionGrantSpark" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.connectionAdmin",
    "roles/bigquery.jobUser"
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = format("serviceAccount:%s", google_bigquery_connection.gcp_lakehouse_connection_spark.spark[0].service_account_id)
}

resource "google_bigquery_routine" "create_view_ecommerce" {
  project         = module.project-services.project_id
  dataset_id      = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  routine_id      = "create_view_ecommerce"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("${path.module}/src/sql/view_ecommerce.sql")
}

resource "google_bigquery_routine" "create_iceberg_tables" {
  project         = module.project-services.project_id
  dataset_id      = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  routine_id      = "create_iceberg_tables"
  routine_type    = "PROCEDURE"
  language        = "PYTHON"
  definition_body = ""
  spark_optiions {
    connection      = google_bigquery_connection.gcp_lakehouse_connection_spark.name
    runtime_version = "2.1"
    main_file_uri   = google_storage_bucket_object.pyspark_file.self_link
    properties = {
      "spark.sql.catalog.lakehouse_catalog" : "org.apache.iceberg.spark.SparkCatalog",
      "spark.sql.catalog.lakehouse_catalog.blms_catalog" : "lakehouse_catalog",
      "spark.sql.catalog.lakehouse_catalog.catalog-impl" : "org.apache.iceberg.gcp.biglake.BigLakeCatalog",
      "spark.sql.catalog.lakehouse_catalog.gcp_location" : var.region,
      "spark.sql.catalog.lakehouse_catalog.gcp_project" : project_id,
      "spark.sql.catalog.lakehouse_catalog.warehouse" : "${google_storage_bucket.warehouse_bucket.url}/warehouse",
      "spark.jars.packages" : "org.apache.iceberg:iceberg-spark-runtime-3.3_2.13:1.2.1"
      "spark.dataproc.driverEnv.lakehouse_catalog" : "lakehouse_catalog"
      "spark.dataproc.driverEnv.lakehouse_database" : "lakehouse_database"
      "spark.dataproc.driverEnv.bq_dataset" : google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
      "spark.dataproc.driverEnv.bq_gcs_connection" : google_bigquery_connection.spark.name
    }
  }
}