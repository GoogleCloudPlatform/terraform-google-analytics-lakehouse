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
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "datacatalog.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "metastore.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com"
  ]
}

resource "time_sleep" "wait_after_apis_activate" {
  depends_on      = [module.project-services]
  create_duration = "30s"
}


resource "google_project_service_identity" "pubsub" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "pubsub.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}

resource "google_project_service_identity" "workflows" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "workflows.googleapis.com"
  depends_on = [time_sleep.wait_after_apis_activate]
}
resource "google_project_service_identity" "dataplex_sa" {
  provider   = google-beta
  project    = module.project-services.project_id
  service    = "dataplex.googleapis.com"
  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent]
}

#eventarc svg agent permissions
resource "google_project_iam_member" "eventarc_svg_agent" {
  project = module.project-services.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.eventarc.email}"

  depends_on = [
    google_project_service_identity.eventarc
  ]
}

resource "google_project_iam_member" "eventarc_log_writer" {
  project = module.project-services.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_project_service_identity.eventarc.email}"

  depends_on = [
    google_project_iam_member.eventarc_svg_agent
  ]
}

#default compute permissions for cloud functions
resource "google_project_iam_member" "workflow_event_receiver" {
  project = module.project-services.project_id
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}


# Set up service accounts fine grain sec.
resource "google_service_account" "marketing_user" {
  project      = module.project-services.project_id
  account_id   = "user-marketing-sa-${random_id.id.hex}"
  display_name = "Service Account for marketing user"
}

# Set up service accounts fine grain sec.
resource "google_service_account" "lake_admin_user" {
  project      = module.project-services.project_id
  account_id   = "user-lake-admin-sa-${random_id.id.hex}"
  display_name = "Service Account for lake admin user"
}

# Set up service accounts fine grain sec.
resource "google_service_account" "data_analyst_user" {
  project      = module.project-services.project_id
  account_id   = "user-analyst-sa-${random_id.id.hex}"
  display_name = "Service Account for  user"
}

#get gcs svc account
data "google_storage_project_service_account" "gcs_account" {
  project = module.project-services.project_id
}


#give workflows_sa bq data access
resource "google_project_iam_member" "workflows_sa_bq_connection" {
  project = module.project-services.project_id
  role    = "roles/bigquery.connectionAdmin"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_service_account.workflows_sa
  ]
}

# Set up BigQuery resources
# # Create the BigQuery dataset
resource "google_bigquery_dataset" "gcp_lakehouse_ds" {
  project       = module.project-services.project_id
  dataset_id    = "gcp_lakehouse_ds"
  friendly_name = "My gcp_lakehouse Dataset"
  description   = "My gcp_lakehouse Dataset with tables"
  location      = var.region
  labels        = var.labels
  depends_on    = [time_sleep.wait_after_adding_eventarc_svc_agent]
}


resource "google_bigquery_routine" "create_view_ecommerce" {
  project         = module.project-services.project_id
  dataset_id      = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  routine_id      = "create_view_ecommerce"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("${path.module}/assets/sql/view_ecommerce.sql")
}

# # Create a BigQuery connection
resource "google_bigquery_connection" "gcp_lakehouse_connection" {
  project       = module.project-services.project_id
  connection_id = "gcp_lakehouse_connection"
  location      = var.region
  friendly_name = "gcp lakehouse storage bucket connection"
  cloud_resource {}
  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent]
}



## This grants permissions to the service account of the connection created in the last step.
resource "google_project_iam_member" "connectionPermissionGrant" {
  project = module.project-services.project_id
  role    = "roles/storage.objectViewer"
  member  = format("serviceAccount:%s", google_bigquery_connection.gcp_lakehouse_connection.cloud_resource[0].service_account_id)
}

#set up workflows svg acct
resource "google_service_account" "workflows_sa" {
  project      = module.project-services.project_id
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account"
}

#give workflows_sa bq access
resource "google_project_iam_member" "workflows_sa_bq_read" {
  project = module.project-services.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_service_account.workflows_sa
  ]
}

resource "google_project_iam_member" "workflows_sa_log_writer" {
  project = module.project-services.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"

  depends_on = [
    google_service_account.workflows_sa
  ]
}


resource "google_workflows_workflow" "workflow_bqml" {
  name            = "workflow-bqml-create"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "Create BQML Model"
  service_account = google_service_account.workflows_sa.email
  source_contents = file("${path.module}/assets/yaml/workflow_bqml.yaml")
  depends_on      = [google_project_iam_member.workflows_sa_bq_read]


}

resource "google_workflows_workflow" "workflow_bucket_copy" {
  name            = "workflow-bucket-copy"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "Copy data files from public bucket to solution project"
  service_account = google_service_account.workflows_sa.email
  source_contents = file("${path.module}/assets/yaml/bucket_copy.yaml")
  depends_on      = [google_project_iam_member.workflows_sa_bq_read]


}

resource "google_workflows_workflow" "workflows_create_gcp_biglake_tables" {
  name            = "workflow-create-gcp-biglake-tables"
  project         = module.project-services.project_id
  region          = "us-central1"
  description     = "create gcp biglake tables_18"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/assets/yaml/workflow_create_gcp_lakehouse_tables.yaml", {
    data_analyst_user = google_service_account.data_analyst_user.email,
    marketing_user    = google_service_account.marketing_user.email
  })

}

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
  name                        = "gcp-lakehouse-edw-export-${module.project-services.project_id}"
  project                     = module.project-services.project_id
  location                    = "us-central1"
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

}


resource "google_storage_bucket_object" "pyspark_file" {
  bucket = google_storage_bucket.provisioning_bucket.name
  name   = "bigquery.py"
  source = "${path.module}/assets/bigquery.py"

  depends_on = [
    google_storage_bucket.provisioning_bucket
  ]

}


#execute workflows
data "google_client_config" "current" {
}
provider "http" {
}
data "http" "call_workflows_create_gcp_biglake_tables_run" {
  url = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflows_create_gcp_biglake_tables.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    google_workflows_workflow.workflow,
    google_workflows_workflow.workflow_bqml,
    google_workflows_workflow.workflow_create_gcp_lakehouse_tables,
    google_workflows_workflow.workflow_bucket_copy,
  ]
}

data "http" "call_workflows_bucket_copy_run" {
  url = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflow_bucket_copy.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    module.project-services,
    google_storage_bucket.provisioning_bucket,
    google_storage_bucket.destination_bucket,
    google_project_service_identity.workflows,
    google_service_account.workflows_sa,
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_dataproc_role,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_connection.gcp_lakehouse_connection,
    google_project_iam_member.connectionPermissionGrant,
    google_workflows_workflow.workflow_bucket_copy
  ]
}

data "http" "call_workflows_create_views_and_others" {
  url = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.workflow_create_views_and_others.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    module.project-services,
    google_storage_bucket.provisioning_bucket,
    google_storage_bucket.destination_bucket,
    google_project_service_identity.workflows,
    google_service_account.workflows_sa,
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_dataproc_role,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_connection.gcp_lakehouse_connection,
    google_project_iam_member.connectionPermissionGrant,
    google_workflows_workflow.workflow_create_views_and_others
  ]
}

data "http" "call_workflows_create_iceberg_table" {
  url = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.initial-workflow-pyspark.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    module.project-services,
    google_storage_bucket.provisioning_bucket,
    google_storage_bucket.destination_bucket,
    google_project_service_identity.workflows,
    google_service_account.workflows_sa,
    google_project_iam_member.workflow_service_account_invoke_role,
    google_project_iam_member.workflows_sa_bq_data,
    google_project_iam_member.workflows_sa_gcs_admin,
    google_project_iam_member.workflows_sa_bq_resource_mgr,
    google_project_iam_member.workflow_service_account_token_role,
    google_project_iam_member.workflows_sa_bq_connection,
    google_project_iam_member.workflows_sa_bq_read,
    google_project_iam_member.workflows_sa_log_writer,
    google_project_iam_member.workflow_service_account_dataproc_role,
    google_project_iam_member.workflow_service_account_bqadmin,
    google_bigquery_dataset.gcp_lakehouse_ds,
    google_bigquery_connection.gcp_lakehouse_connection,
    google_project_iam_member.connectionPermissionGrant,
    google_workflows_workflow.initial-workflow-pyspark
  ]
}


output "workflow_return_bucket_copy" {
  value = data.http.call_workflows_bucket_copy_run.response_body
}

output "workflow_return_create_bq_tables" {
  value = data.http.call_workflows_create_gcp_biglake_tables_run.response_body
}

output "call_workflows_create_views_and_others" {
  value = data.http.call_workflows_create_views_and_others.response_body
}
output "call_workflows_create_iceberg_table" {
  value = data.http.call_workflows_create_iceberg_table.response_body
}

#give dataplex access to biglake bucket
resource "google_project_iam_member" "dataplex_bucket_access" {
  project = module.project-services.project_id
  role    = "roles/dataplex.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.dataplex_sa.email}"

  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent]
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
  depends_on = [time_sleep.wait_after_adding_eventarc_svc_agent, google_project_iam_member.dataplex_bucket_access]
}


#ICEBERG setup
# Set up networking
resource "google_compute_network" "default_network" {
  project                 = module.project-services.project_id
  name                    = "vpc-${var.use_case_short}"
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "subnet" {
  project                  = module.project-services.project_id
  name                     = "dataproc-subnet"
  ip_cidr_range            = "10.3.0.0/16"
  region                   = var.region
  network                  = google_compute_network.default_network.id
  private_ip_google_access = true

  depends_on = [
    google_compute_network.default_network,
  ]
}

# Firewall rule for dataproc cluster
resource "google_compute_firewall" "subnet_firewall_rule" {
  project = module.project-services.project_id
  name    = "dataproc-firewall"
  network = google_compute_network.default_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  source_ranges = ["10.3.0.0/16"]

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}


# Set up Dataproc service account for the Cloud Function to execute as
# # Set up the Dataproc service account
resource "google_service_account" "dataproc_service_account" {
  project      = module.project-services.project_id
  account_id   = "dataproc-sa-${random_id.id.hex}"
  display_name = "Service Account for Dataproc Execution"
}

# # Grant the Dataproc service account Object Create / Delete access
resource "google_project_iam_member" "dataproc_service_account_storage_role" {
  project = module.project-services.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"

  depends_on = [
    google_service_account.dataproc_service_account
  ]
}

# # Grant the Dataproc service account BQ Connection Access
resource "google_project_iam_member" "dataproc_service_account_bq_connection_role" {
  project = module.project-services.project_id
  role    = "roles/bigquery.connectionUser"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"

  depends_on = [
    google_service_account.dataproc_service_account
  ]
}

# # Grant the Dataproc service account BigLake access
resource "google_project_iam_member" "dataproc_service_account_biglake_role" {
  project = module.project-services.project_id
  role    = "roles/biglake.admin"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"

  depends_on = [
    google_service_account.dataproc_service_account
  ]
}

# # Grant the Dataproc service account dataproc access
resource "google_project_iam_member" "dataproc_service_account_dataproc_worker_role" {
  project = module.project-services.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.dataproc_service_account.email}"

  depends_on = [
    google_service_account.dataproc_service_account
  ]
}

# Set up Storage Buckets
# # Set up the export storage bucket
resource "google_storage_bucket" "export_bucket" {
  name                        = "gcp-${var.use_case_short}-export-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = "us-central1"
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the raw storage bucket
resource "google_storage_bucket" "raw_bucket" {
  name                        = "gcp-${var.use_case_short}-raw-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

# # Set up the provisioning bucketstorage bucket
resource "google_storage_bucket" "provisioning_bucket_short" {
  name                        = "gcp-${var.use_case_short}-provisioner-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  # public_access_prevention = "enforced"
}

# Set up BigQuery resources
# # Create the BigQuery dataset
resource "google_bigquery_dataset" "ds" {
  project                    = module.project-services.project_id
  dataset_id                 = "gcp_${var.use_case_short}"
  friendly_name              = "My Dataset"
  description                = "My Dataset with tables"
  location                   = var.region
  labels                     = var.labels
  delete_contents_on_destroy = var.force_destroy
}

# # Create a BigQuery connection
resource "google_bigquery_connection" "ds_connection" {
  project       = module.project-services.project_id
  connection_id = "gcp_gcs_connection"
  location      = var.region
  friendly_name = "Storage Bucket Connection"
  cloud_resource {}
}

# # Grant IAM access to the BigQuery Connection account for Cloud Storage
resource "google_project_iam_member" "bq_connection_iam_object_viewer" {
  project = module.project-services.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_bigquery_connection.ds_connection.cloud_resource[0].service_account_id}"

  depends_on = [
    google_bigquery_connection.ds_connection
  ]
}

# # Create a BigQuery external table.
resource "google_bigquery_table" "tbl_thelook_events" {
  dataset_id          = google_bigquery_dataset.ds.dataset_id
  table_id            = "events"
  project             = module.project-services.project_id
  deletion_protection = var.deletion_protection

  external_data_configuration {
    autodetect    = true
    connection_id = google_bigquery_connection.ds_connection.name #TODO: Change other solutions to remove hardcoded reference
    source_format = "PARQUET"
    source_uris   = ["gs://${var.public_data_bucket}/thelook_ecommerce/events-*.Parquet"]

  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "user_id",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "sequence_number",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "session_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "ip_address",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "postal_code",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "browser",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "traffic_source",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "uri",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "event_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  }
]
EOF

  depends_on = [
    google_bigquery_connection.ds_connection,
    google_storage_bucket.raw_bucket
  ]
}


# Set up Workflows service account
# # Set up the Workflows service account
resource "google_service_account" "workflow_service_account" {
  project      = module.project-services.project_id
  account_id   = "cloud-workflow-sa-${random_id.id.hex}"
  display_name = "Service Account for Cloud Workflows"
}

# # Grant the Workflow service account Workflows Admin
resource "google_project_iam_member" "workflow_service_account_invoke_role" {
  project = module.project-services.project_id
  role    = "roles/workflows.admin"
  member  = "serviceAccount:${google_service_account.workflow_service_account.email}"

  depends_on = [
    google_service_account.workflow_service_account
  ]
}

# # Grant the Workflow service account Dataproc admin
resource "google_project_iam_member" "workflow_service_account_dataproc_role" {
  project = module.project-services.project_id
  role    = "roles/dataproc.admin"
  member  = "serviceAccount:${google_service_account.workflow_service_account.email}"

  depends_on = [
    google_service_account.workflow_service_account
  ]
}

# # Grant the Workflow service account BQ admin
resource "google_project_iam_member" "workflow_service_account_bqadmin" {
  project = module.project-services.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.workflow_service_account.email}"

  depends_on = [
    google_service_account.workflow_service_account
  ]
}

resource "google_workflows_workflow" "workflow" {
  name            = "initial-workflow-pyspark"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Runs post Terraform setup steps for Solution in Console"
  service_account = google_service_account.workflow_service_account.id
  source_contents = templatefile("${path.module}/assets/yaml/workflow_pyspark.yaml", {
    dataproc_service_account = google_service_account.dataproc_service_account.email,
    provisioner_bucket       = google_storage_bucket.provisioning_bucket.name,
    warehouse_bucket         = google_storage_bucket.raw_bucket.name,
    temp_bucket              = google_storage_bucket.raw_bucket.name
  })

}


# Create Eventarc Trigger
// Create a Pub/Sub topic.
resource "google_pubsub_topic" "topic" {
  name    = "provisioning-topic"
  project = module.project-services.project_id
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = module.project-services.project_id
  topic   = google_pubsub_topic.topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_storage_notification" "notification_provisioning_bucket" {
  provider       = google
  bucket         = google_storage_bucket.provisioning_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.topic.id
  depends_on     = [google_pubsub_topic_iam_binding.binding]
}

resource "google_storage_notification" "notification" {
  provider       = google
  bucket         = google_storage_bucket.provisioning_bucket_short.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.topic.id
  depends_on     = [google_pubsub_topic_iam_binding.binding]
}

resource "google_eventarc_trigger" "trigger_pubsub_for_provisioning_bucket" {
  project  = module.project-services.project_id
  name     = "trigger-pubsub-provisioning-bucket"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"


  }
  destination {
    workflow = google_workflows_workflow.workflows_create_gcp_biglake_tables.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.topic.id
    }
  }
  service_account = google_service_account.eventarc_service_account.email

  depends_on = [
    google_workflows_workflow.workflows_create_gcp_biglake_tables,
    google_project_iam_member.eventarc_service_account_invoke_role
  ]
}



resource "google_eventarc_trigger" "trigger_pubsub_tf" {
  project  = module.project-services.project_id
  name     = "trigger-pubsub-tf"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"


  }
  destination {
    workflow = google_workflows_workflow.workflow.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.topic.id
    }
  }
  service_account = google_service_account.eventarc_service_account.email

  depends_on = [
    google_workflows_workflow.workflow,
    google_project_iam_member.eventarc_service_account_invoke_role
  ]
}

# Set up Eventarc service account for the Cloud Function to execute as
# # Set up the Eventarc service account
resource "google_service_account" "eventarc_service_account" {
  project      = module.project-services.project_id
  account_id   = "eventarc-sa-${random_id.id.hex}"
  display_name = "Service Account for Cloud Eventarc"
}

# # Grant the Eventar service account Workflow Invoker Access
resource "google_project_iam_member" "eventarc_service_account_invoke_role" {
  project = module.project-services.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_service_account.email}"

  depends_on = [
    google_service_account.eventarc_service_account
  ]
}

resource "google_project_iam_member" "workflow_service_account_token_role" {
  project = module.project-services.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.workflow_service_account.email}"

  depends_on = [
    google_service_account.workflow_service_account
  ]
}

resource "google_data_catalog_taxonomy" "gcp_lakehouse_taxonomy" {
  provider               = google
  project                = module.project-services.project_id
  display_name           = "gcp_lakehouse_taxonomy"
  description            = "A collection of policy tags"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
  region                 = var.region
}
