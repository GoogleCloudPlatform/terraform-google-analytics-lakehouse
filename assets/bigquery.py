#!/usr/bin/python
"""BigQuery I/O with BigLake Iceberg PySpark example."""
from pyspark.sql import SparkSession
import os

spark = SparkSession.builder.appName("spark-bigquery-demo").getOrCreate()

catalog = os.getenv("lakehouse_catalog", "lakehouse_catalog")
database = os.getenv("lakehouse_db", "lakehouse_db")
bucket = os.getenv("temp_bucket", "gcp-lakehouse-provisioner-8a68acad")
bq_dataset = os.getenv("bq_dataset", "gcp_lakehouse_ds")
bq_connection = os.getenv("bq_gcs_connection",
                          "us-central1.gcp_gcs_connection")

# Use the Cloud Storage bucket for temporary BigQuery export data
# used by the connector.
spark.conf.set("temporaryGcsBucket", bucket)

# Create BigLake Catalog and Database if they are not already created.
spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {catalog};")
spark.sql(f"CREATE DATABASE IF NOT EXISTS {catalog}.{database};")
spark.sql(f"DROP TABLE IF EXISTS {catalog}.{database}.agg_events_iceberg;")


# Load data from BigQuery.
events = spark.read.format("bigquery") \
    .option("table", "gcp_lakehouse_ds.events") \
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
