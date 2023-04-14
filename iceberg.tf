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
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
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
