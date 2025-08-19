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

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 18.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "biglake.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "dataprocrm.googleapis.com",
    "iam.googleapis.com",
    "managedkafka.googleapis.com",
    "notebooks.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "storage-api.googleapis.com",
    "workflows.googleapis.com",
  ]
}

resource "time_sleep" "wait_after_apis_activate" {
  depends_on      = [module.project-services]
  create_duration = "30s"
}

#random id
resource "random_id" "id" {
  byte_length = 4
}

# Set up Storage Buckets

# # Set up the warehouse storage bucket
resource "google_storage_bucket" "warehouse_bucket" {
  name                        = "${var.use_case_short}-warehouse-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

# Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "provisioning_bucket" {
  name                        = "${var.use_case_short}-provisioner-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

# Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "iceberg_bucket" {
  name                        = "${var.use_case_short}-iceberg-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "ga4_images_bucket" {
  name                        = "ga4-images-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "textocr_images_bucket" {
  name                        = "textocr-images-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "taxi_bucket" {
  name                        = "taxi-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "thelook_bucket" {
  name                        = "thelook-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}


resource "google_storage_bucket_object" "bigquery_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/src/python/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Bigtable task file
resource "google_storage_bucket_object" "bigtable_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigtable.py"
  source = "${path.module}/src/python/bigtable.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Kafka + BigQuery task file
resource "google_storage_bucket_object" "kafka_bigquery_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "kafka-bigquery.py"
  source = "${path.module}/src/python/kafka_bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Upload Spark + BigQuery notebook
resource "google_storage_bucket_object" "spark_biguery_notebook_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "spark_in_bigquery.ipynb"
  source = "${path.module}/src/ipynb/spark_in_bigquery.ipynb"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Upload BQML notebook
resource "google_storage_bucket_object" "bqml_notebook_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "create_embeddings_with_bqml.ipynb"
  source = "${path.module}/src/ipynb/create_embeddings_with_bqml.ipynb"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# Upload SparkML notebook
resource "google_storage_bucket_object" "sparkml_notebook_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "purchase_predictions_sparkml.ipynb"
  source = "${path.module}/src/ipynb/purchase_predictions_sparkml.ipynb"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

resource "google_storage_bucket" "spark-log-directory" {
  name                        = "gcp-${var.use_case_short}-spark-log-directory-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "phs-staging-bucket" {
  name                        = "gcp-${var.use_case_short}-phs-staging-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "phs-temp-bucket" {
  name                        = "gcp-${var.use_case_short}-phs-temp-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "sparkml-model-bucket" {
  name                        = "gcp-${var.use_case_short}-model-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}
