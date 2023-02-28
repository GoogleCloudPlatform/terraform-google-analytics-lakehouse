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
    "run.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "artifactregistry.googleapis.com",
    "metastore.googleapis.com",
    "dataproc.googleapis.com",
    "dataplex.googleapis.com",
    "datacatalog.googleapis.com",
    "workflows.googleapis.com"

  ]
}

resource "time_sleep" "wait_pre_event_arc_api" {
  depends_on = [module.project-services]
  #actually waits 180 seconds
  create_duration = "120s"
}
resource "time_sleep" "wait_post_event_arc_api" {
  depends_on = [module.project-services,
  google_eventarc_trigger.trigger_pubsub_tf]
  #actually waits 180 seconds
  create_duration = "240s"
}

#random id
resource "random_id" "id" {
  byte_length = 4
}

# [START eventarc_workflows_create_serviceaccount]

# Create a service account for Eventarc trigger and Workflows
resource "google_service_account" "eventarc_workflows_service_account" {
  provider     = google-beta
  project      = module.project-services.project_id
  account_id   = "eventarc-workflows-sa"
  display_name = "Eventarc Workflows Service Account"
}

# Grant the logWriter role to the service account
resource "google_project_iam_binding" "project_binding_eventarc" {
  provider = google-beta
  project  = module.project-services.project_id
  role     = "roles/logging.logWriter"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [time_sleep.wait_pre_event_arc_api, google_service_account.eventarc_workflows_service_account]
}

# Grant the workflows.invoker role to the service account
resource "google_project_iam_binding" "project_binding_workflows" {
  provider = google-beta
  project  = module.project-services.project_id
  role     = "roles/workflows.invoker"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

# Grant the workflows.invoker role to the service account
resource "google_project_iam_binding" "project_binding_invoker" {
  provider = google-beta
  project  = module.project-services.project_id
  role     = "roles/run.invoker"

  members = ["serviceAccount:${google_service_account.eventarc_workflows_service_account.email}"]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}


# [END eventarc_workflows_create_serviceaccount]

# [START eventarc_workflows_deploy]
# Define and deploy a workflow

resource "google_workflows_workflow" "workflow_trigger_for_eventarc" {
  name            = "workflow"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "Trigger to prime eventarc"
  service_account = google_service_account.eventarc_workflows_service_account.id
  source_contents = <<-EOF
  - getCurrentTime:
      call: http.get
      args:
          url: https://us-central1-workflowsample.cloudfunctions.net/datetime
      result: CurrentDateTime
  - returnOutput:
      return: $${CurrentDateTime.body}
EOF
}

resource "google_eventarc_trigger" "trigger_pubsub_tf" {
  name     = "trigger-pubsub-workflow-tf"
  project  = module.project-services.project_id
  provider = google-beta
  location = "us-central1"
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    workflow = google_workflows_workflow.workflow_trigger_for_eventarc.id
  }


  service_account = google_service_account.eventarc_workflows_service_account.id

  depends_on = [time_sleep.wait_pre_event_arc_api,
  google_service_account.eventarc_workflows_service_account]
}

# [END eventarc_create_pubsub_trigger]

resource "google_project_service_identity" "pos_eventarc_sa" {
  provider = google-beta
  project  = module.project-services.project_id
  service  = "eventarc.googleapis.com"
  depends_on = [time_sleep.wait_pre_event_arc_api,
  google_eventarc_trigger.trigger_pubsub_tf]
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
  depends_on    = [time_sleep.wait_post_event_arc_api]
}

# # Create a BigQuery connection
resource "google_bigquery_connection" "gcp_lakehouse_connection" {
  project       = var.project_id
  connection_id = "gcp_lakehouse_connection"
  location      = var.region
  friendly_name = "gcp lakehouse storage bucket connection"
  cloud_resource {}
  depends_on = [time_sleep.wait_post_event_arc_api]
}


# Create BigQuery external tables
resource "google_bigquery_table" "gcp_tbl_distribution_centers" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_distribution_centers"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on          = [time_sleep.wait_post_event_arc_api]


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
  depends_on          = [time_sleep.wait_post_event_arc_api]


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
  depends_on          = [time_sleep.wait_post_event_arc_api]


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
  depends_on          = [time_sleep.wait_post_event_arc_api]


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
  depends_on          = [time_sleep.wait_post_event_arc_api]


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
  depends_on          = [time_sleep.wait_post_event_arc_api]


  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/products-*.Parquet"]

  }
}
#bq table on top of biglake bucket.  
resource "google_bigquery_table" "gcp_tbl_users" {
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  table_id            = "gcp_tbl_users"
  project             = var.project_id
  deletion_protection = var.deletion_protection
  depends_on          = [time_sleep.wait_post_event_arc_api]

  #steve



  external_data_configuration {
    autodetect    = true
    connection_id = "${var.project_id}.${var.region}.gcp_lakehouse_connection"
    source_format = "PARQUET"
    source_uris   = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/users-*.Parquet"]

  }
}

#resource "google_dataproc_metastore_service" "gcp_default" {
# service_id = "gcp-default-metastore"
#location   = "us-central1"
#port       = 9080
#project  = var.project_id
#depends_on = [time_sleep.wait_post_event_arc_api]
#}


# # Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "provisioning_bucket" {
  name                        = "gcp_gcf_source_code-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

}

# # Set up the export storage bucket
resource "google_storage_bucket" "destination_bucket" {
  name                        = "gcp-edw-export-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = "us-central1"
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

}


# Set up service account for the Cloud Function to execute as
resource "google_service_account" "cloud_function_service_account" {
  project      = module.project-services.project_id
  account_id   = "cloud-function-sa-${random_id.id.hex}"
  display_name = "Service Account for Cloud Function Execution"
}

resource "google_project_iam_member" "cloud_function_service_account_editor_role" {
  project = module.project-services.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.cloud_function_service_account.email}"

  depends_on = [
    google_service_account.cloud_function_service_account
  ]
}


resource "google_project_iam_member" "cloud_function_service_account_function_invoker" {
  project = module.project-services.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_function_service_account.email}"

  depends_on = [  
    google_service_account.cloud_function_service_account
  ]
}


# Create a Cloud Function resource
# # Zip the function file
data "archive_file" "bigquery_external_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/assets/bigquery-external-function"
  output_path = "${path.module}/assets/bigquery-external-function.zip"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]
}




# # Place the cloud function code (zip file) on Cloud Storage
resource "google_storage_bucket_object" "cloud_function_zip_upload" {
  name   = "assets/bigquery-external-function.zip"
  bucket = google_storage_bucket.provisioning_bucket.name
  source = data.archive_file.bigquery_external_function_zip.output_path

  depends_on = [
    google_storage_bucket.provisioning_bucket,
    data.archive_file.bigquery_external_function_zip
  ]
}


#get gcs svc account
data "google_storage_project_service_account" "gcs_account" {
  project = module.project-services.project_id
}

resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = module.project-services.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_project_iam_member" "gcs_run_invoker" {
  project = module.project-services.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

#Create gcp cloud function
resource "google_cloudfunctions2_function" "function" {
  #provider = google-beta
  project     = module.project-services.project_id
  name        = "gcp-run-gcf-${random_id.id.hex}"
  location    = var.region
  description = "run python code that Terraform cannot currently handle"

  build_config {
    runtime     = "python310"
    entry_point = "gcs_copy"
    source {
      storage_source {
        bucket = google_storage_bucket.provisioning_bucket.name
        object = "assets/bigquery-external-function.zip"
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 540
    environment_variables = {
      PROJECT_ID            = module.project-services.project_id
      DESTINATION_BUCKET_ID = google_storage_bucket.destination_bucket.name
      SOURCE_BUCKET_ID      = var.bucket_name
    }
    service_account_email = google_service_account.cloud_function_service_account.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.provisioning_bucket.name
    }
    retry_policy = "RETRY_POLICY_RETRY"
  }

  depends_on = [
    google_storage_bucket.provisioning_bucket,
    google_project_iam_member.cloud_function_service_account_editor_role,
    google_project_service_identity.pos_eventarc_sa,
    time_sleep.wait_post_event_arc_api
  ]
}

resource "google_project_iam_member" "workflow_event_receiver" {
  project = module.project-services.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_admin_to_compute_default" {
  project = module.project-services.project_id
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


resource "google_storage_bucket_object" "startfile" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "startfile"
  source = "${path.module}/assets/startfile"

  depends_on = [
    google_cloudfunctions2_function.function
  ]

}

#dataplex
#get dataplex svc acct info
resource "google_project_service_identity" "dataplex_sa" {
  provider   = google-beta
  project    = var.project_id
  service    = "dataplex.googleapis.com"
  depends_on = [time_sleep.wait_post_event_arc_api]
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

  project    = var.project_id
  depends_on = [time_sleep.wait_post_event_arc_api]
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
  depends_on   = [time_sleep.wait_post_event_arc_api]
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = var.project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"

  depends_on = [time_sleep.wait_post_event_arc_api]
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
    name = "projects/${var.project_id}/buckets/${google_storage_bucket.destination_bucket.name}"
    type = "STORAGE_BUCKET"
  }

  project    = var.project_id
  depends_on = [time_sleep.wait_post_event_arc_api, google_project_iam_member.dataplex_bucket_access]
}

#add run invoker to cloud run service agent NFIITW
#resource "google_project_service_identity" "cloud_run_sa" {
#  provider = google-beta
#  project  = module.project-services.project_id
#  service  = "run.googleapis.com"
#  depends_on = [google_cloudfunctions2_function.function]
#}

