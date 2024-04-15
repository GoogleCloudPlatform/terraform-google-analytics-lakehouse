#!/usr/bin/python
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""BigQuery I/O with BigLake Iceberg PySpark example."""
from pyspark.sql import SparkSession
import json
import os

spark = SparkSession \
    .builder \
    .appName("spark-bigquery-demo") \
    .enableHiveSupport() \
    .getOrCreate()


def load_arg(arg):
    return str(json.loads(os.environ[f"BIGQUERY_PROC_PARAM.{arg}"]))


catalog = load_arg("lakehouse_catalog")
database = load_arg("lakehouse_database")
bq_dataset = load_arg("bq_dataset")

# Delete the BigLake Catalog if it currently exists to ensure proper setup.
spark.sql(f"DROP NAMESPACE IF EXISTS {catalog} CASCADE;")

# Create BigLake Catalog and Database if they are not already created.
spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {catalog};")
spark.sql(f"CREATE DATABASE IF NOT EXISTS {catalog}.{database};")
spark.sql(f"DROP TABLE IF EXISTS {catalog}.{database}.agg_events_iceberg;")

# Load data from BigQuery.
events = spark.read.format("bigquery") \
    .option("table", "gcp_primary_staging.thelook_ecommerce_events") \
    .load()
events.createOrReplaceTempView("events")

# Create Iceberg Table if not exists
spark.sql(
    f"""CREATE TABLE IF NOT EXISTS {catalog}.{database}.agg_events_iceberg
    (user_id string, event_count bigint)
    USING iceberg
            TBLPROPERTIES(
                bq_table='{bq_dataset}.agg_events_iceberg');
    """
)

# Create Iceberg Table if not exists
spark.sql(
    f"""INSERT INTO {catalog}.{database}.agg_events_iceberg
    (user_id, event_count)
    select user_id, count(session_id)
    from events
    group by user_id;
    """
)
