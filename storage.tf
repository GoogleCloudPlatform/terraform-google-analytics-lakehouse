/**
 * Copyright 2024 Google LLC
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

# Set up Storage Buckets

# # Set up the raw storage bucket
resource "google_storage_bucket" "raw_bucket" {
  name                        = "gcp-${var.use_case_short}-raw-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the warehouse storage bucket
resource "google_storage_bucket" "warehouse_bucket" {
  name                        = "gcp-${var.use_case_short}-warehouse-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "provisioning_bucket" {
  name                        = "gcp-${var.use_case_short}-provisioner-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

}

resource "google_storage_bucket" "ga4_images_bucket" {
  name                        = "gcp-${var.use_case_short}-ga4-images-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "textocr_images_bucket" {
  name                        = "gcp-${var.use_case_short}-textocr-images-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

resource "google_storage_bucket" "tables_bucket" {
  name                        = "gcp-${var.use_case_short}-tables-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
}

# # Bucket used to store BI data in Dataplex
resource "google_storage_bucket" "dataplex_bucket" {
  name                        = "gcp-${var.use_case_short}-dataplex-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
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

# # Uploads PySpark file
resource "google_storage_bucket_object" "pyspark_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/src/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}

# # Uploads the post-startup script for the workbench instance.
resource "google_storage_bucket_object" "post_startup_script" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "post_startup.sh"
  source = "${path.module}/src/post_startup.sh"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}


locals {
  buckets = [
    {
      src_path    = "ga4_obfuscated_sample_ecommerce_images/"
      sink_bucket = google_storage_bucket.ga4_images_bucket.name
    },
    {
      src_path    = "new-york-taxi-trips/"
      sink_bucket = google_storage_bucket.textocr_images_bucket.name
    },
    {
      src_path    = "thelook_ecommerce/"
      sink_bucket = google_storage_bucket.tables_bucket.name
    },
    {
      src_path    = "views/"
      sink_bucket = google_storage_bucket.dataplex_bucket.name
    },
  ]
}

resource "google_storage_transfer_job" "jobs" {
  for_each = { for p in local.buckets : p.src_path => p }

  description = "Stage data in the deployment"
  project     = module.project-services.project_id

  transfer_spec {
    gcs_data_sink {
      bucket_name = each.value.sink_bucket
    }
    gcs_data_source {
      bucket_name = var.public_data_bucket
      path        = each.key
    }
  }

  schedule {
    schedule_start_date {
      year  = 1970
      month = 1
      day   = 1
    }
    schedule_end_date {
      year  = 1970
      month = 1
      day   = 1
    }
  }

  depends_on = [google_project_iam_member.gcs_sa_roles]
}

resource "time_sleep" "wait_after_copy_data" {
  create_duration = "60s"
  depends_on = [
    google_storage_transfer_job.jobs
  ]
}