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
from bigquery.spark.procedure import SparkProcParamContext

spark = SparkSession \
    .builder \
    .appName("spark-bigquery-demo") \
    .enableHiveSupport() \
    .getOrCreate()

spark_proc_param_context = SparkProcParamContext.getOrCreate

catalog = spark_proc_param_context.catalog
database = spark_proc_param_context.database
bq_dataset = spark_proc_param_context.bq_dataset
bq_connection = spark_proc_param_context.bq_connection

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
                bq_table='{bq_dataset}.agg_events_iceberg',
                bq_connection='{bq_connection}');
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
