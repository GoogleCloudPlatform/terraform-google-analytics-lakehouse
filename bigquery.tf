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

# # Create a BigQuery connection for Storage
resource "google_bigquery_connection" "storage" {
  project       = module.project-services.project_id
  connection_id = "storage"
  location      = var.region
  friendly_name = "gcp lakehouse storage connection"
  cloud_resource {}
}

resource "google_project_iam_member" "connection_permission_grant_storage" {
  for_each = toset([
    "roles/aiplatform.admin",
    "roles/biglake.admin",
    "roles/bigquery.admin",
    "roles/dataproc.worker",
    "roles/storage.objectAdmin"
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = format("serviceAccount:%s", google_bigquery_connection.storage.cloud_resource[0].service_account_id)
}

# # Create a taxonomy for policy tags
resource "google_data_catalog_taxonomy" "taxonomy" {
  project                = module.project-services.project_id
  region                 = var.region
  display_name           = "taxonomy-${module.project-services.project_id}"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

# # Create a policy tag
resource "google_data_catalog_policy_tag" "policy_tag" {
  taxonomy     = google_data_catalog_taxonomy.taxonomy.name
  display_name = "tag"
  description  = "Data that is considered sensitive"
}

# # Create a data policy for that tag
resource "google_bigquery_datapolicy_data_policy" "data_policy" {
  project          = module.project-services.project_id
  location         = var.region
  data_policy_id   = "masking_policy"
  policy_tag       = google_data_catalog_policy_tag.policy_tag.name
  data_policy_type = "DATA_MASKING_POLICY"

  data_masking_policy {
    predefined_expression = "ALWAYS_NULL"
  }
}

# # Create BigLake Tables for Apache Iceberg
resource "google_bigquery_table" "users" {
  project             = module.project-services.project_id
  table_id            = "users"
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  friendly_name       = "BigQuery Table for Apache Iceberg: users"
  description         = "BigQuery Table for Apache Iceberg: users"
  deletion_protection = false

  biglake_configuration {
    connection_id = google_bigquery_connection.storage.name
    storage_uri   = "${google_storage_bucket.iceberg_bucket.url}/users}"
    file_format   = "PARQUET"
    table_format  = "ICEBERG"
  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "first_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "last_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "email",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "age",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "gender",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "state",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "street_address",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "postal_code",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "country",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "latitude",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
  {
    "name": "longitude",
    "type": "FLOAT",
    "mode": "NULLABLE"
  },
  {
    "name": "traffic_source",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
]
EOF

  depends_on = [
    google_project_iam_member.connection_permission_grant_storage
  ]
}

resource "google_bigquery_table" "order_items" {
  project             = module.project-services.project_id
  table_id            = "order_items"
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  friendly_name       = "BigQuery Table for Apache Iceberg: order_items"
  description         = "BigQuery Table for Apache Iceberg: order_items"
  deletion_protection = false

  biglake_configuration {
    connection_id = google_bigquery_connection.storage.name
    storage_uri   = "${google_storage_bucket.iceberg_bucket.url}/order-items}"
    file_format   = "PARQUET"
    table_format  = "ICEBERG"
  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "order_id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "user_id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "product_id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "inventory_item_id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "status",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "shipped_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "delivered_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "returned_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "sale_price",
    "type": "FLOAT",
    "mode": "NULLABLE"
  }
]
EOF

  depends_on = [
    google_project_iam_member.connection_permission_grant_storage
  ]
}

resource "google_bigquery_table" "taxi" {
  project             = module.project-services.project_id
  table_id            = "taxi"
  dataset_id          = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
  friendly_name       = "BigQuery Table for Apache Iceberg: taxi"
  description         = "BigQuery Table for Apache Iceberg: taxi"
  deletion_protection = false

  biglake_configuration {
    connection_id = google_bigquery_connection.storage.name
    storage_uri   = google_storage_bucket.iceberg_bucket.url
    file_format   = "PARQUET"
    table_format  = "ICEBERG"
  }

  schema = <<EOF
[
  {
    "name": "vendor_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "pickup_datetime",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "dropoff_datetime",
    "type": "TIMESTAMP",
    "mode": "NULLABLE"
  },
  {
    "name": "passenger_count",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "trip_distance",
    "type": "NUMERIC",
    "mode": "NULLABLE"
  },
  {
    "name": "rate_code",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "store_and_fwd_flag",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "payment_type",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "fare_amount",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "extra",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "mta_tax",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "tip_amount",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "tolls_amount",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "imp_surcharge",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "airport_fee",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "total_amount",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "policyTags": {
      "names": ["${google_data_catalog_policy_tag.policy_tag.id}"]
    }
  },
  {
    "name": "pickup_location_id",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "dropoff_location_id",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "data_file_year",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "data_file_month",
    "type": "INTEGER",
    "mode": "NULLABLE"
  }
]
EOF

  depends_on = [
    google_project_iam_member.connection_permission_grant_storage
  ]
}

# Load into Iceberg tables
resource "google_bigquery_job" "load_into_iceberg_table_users" {
  job_id   = "load_into_iceberg_table_users"
  project  = module.project-services.project_id
  location = var.region

  query {
    query = <<-EOT
      SELECT
        id,
        first_name,
        last_name,
        email,
        age,
        gender,
        state,
        street_address,
        postal_code,
        city,
        country,
        latitude,
        longitude,
        traffic_source,
        created_at
      FROM
        `bigquery-public-data.thelook_ecommerce.users"
    EOT

    destination_table {
      project_id = module.project-services.project_id
      dataset_id = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
      table_id   = google_bigquery_table.order_items.table_id
    }

    create_disposition = ""
    write_disposition  = ""
  }
}


resource "google_bigquery_job" "load_into_iceberg_table_order_items" {
  job_id   = "load_into_iceberg_table_order_items"
  project  = module.project-services.project_id
  location = var.region

  load {
    source_uris = [
      "${google_storage_bucket.thelook_bucket.url}/thelook_ecommerce/order_items/*.parquet"
    ]

    destination_table {
      project_id = module.project-services.project_id
      dataset_id = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
      table_id   = google_bigquery_table.order_items.table_id
    }
  }
}

resource "google_bigquery_job" "load_into_iceberg_table_taxi" {
  job_id   = "load_into_iceberg_table_taxi"
  project  = module.project-services.project_id
  location = var.region

  load {
    source_uris = [
      "${google_storage_bucket.taxi_bucket.url}/new-york-taxi-trips/tlc-yellow-trips-2022/*.parquet"
    ]

    destination_table {
      project_id = module.project-services.project_id
      dataset_id = google_bigquery_dataset.gcp_lakehouse_ds.dataset_id
      table_id   = google_bigquery_table.taxi.table_id
    }
  }
}

resource "time_sleep" "wait_after_bq_job" {
  create_duration = "60s"
  depends_on = [
    google_bigquery_job.load_into_iceberg_table
  ]
}

# # Create Dataform repository
resource "google_dataform_repository" "notebooks" {
  provider = google-beta
  project  = module.project-services.project_id
  region   = var.region
  name     = "notebooks"

  labels = {
    single-file-asset-type = "notebooks"
  }
}

# # Execute after Dataplex discovery wait

resource "google_bigquery_job" "create_view_ecommerce" {
  project  = module.project-services.project_id
  location = var.region
  job_id   = "create_view_ecommerce_${random_id.id.hex}"

  query {
    query = file("${path.module}/src/sql/view_ecommerce.sql")

    # Since the query contains DML, these must be set to empty.
    create_disposition = ""
    write_disposition  = ""
  }

  depends_on = [time_sleep.wait_after_project_setup]
}
