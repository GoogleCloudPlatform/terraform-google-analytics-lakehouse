#!/usr/bin/python
# Copyright 2024 Google LLC
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

# This file is used as a part of the Neos journey for the Analytics
# Lakehouse Jumpstart solution. It is not automatically executed as a
# part of the default deployment.

"""Bigtable to PySpark to BigQuery example."""
from pyspark.sql import SparkSession
import sys

# Must provide a project ID and an instance ID.
if len(sys.argv) < 3:
    print("Please provide a project ID and an instance ID.")

project_id = sys.argv[1]
instance_id = sys.argv[2]

# Create a Spark session and configure the spark-bigtable connector.
spark = SparkSession.builder \
          .config("spark.jars",
                  "gs://spark-bigtable-preview/jars/" +
                  "spark-bigtable-0.0.1-preview5-SNAPSHOT.jar") \
          .getOrCreate()

# Create the catalog schema to convert Bigtable columns to Spark.
# "table" defnes the Bigtable namespace and table to read data from.
# "rowkey" defines the rowkey.
# "columns" are formatted as
# "SPARK_DF_COLUMN_NAME":{
#                          "cf":"BIGTABLE_COLUMN_FAMILY",
#                          "col":"BIGTABLE_COLUMN_NAME",
#                          "type":"BIGTABLE_TYPE"
#                        }
catalog = ''.join(("""{
      "table":{"namespace":"default", "name":"UserPersonalization"},
      "rowkey":"rowkey",
      "columns":{
        "_rowkey":{"cf":"rowkey", "col":"rowkey", "type":"string"},
        "rec0":{
                 "cf":"Recommendations",
                 "col":"Recommendation0",
                 "type":"string"
               },
        "rec1":{
                 "cf":"Recommendations",
                 "col":"Recommendation1",
                 "type":"string"
               },
        "rec2":{
                 "cf":"Recommendations",
                 "col":"Recommendation2",
                 "type":"string"
               },
        "rec3":{
                 "cf":"Recommendations",
                 "col":"Recommendation3",
                 "type":"string"
        }
      }
      }""").split())

# Load Bigtable data.
df = spark.read \
        .format('bigtable') \
        .option('spark.bigtable.project.id', project_id) \
        .option('spark.bigtable.instance.id', instance_id) \
        .options(catalog=catalog) \
        .load()


# Create new dfs counting each recommended item per rec position.
# Rename columns to join later.
def groupby_count_rename(df, col):
    return df.groupBy(col) \
             .count() \
             .withColumnRenamed(col, "item") \
             .withColumnRenamed("count", col)


r0 = groupby_count_rename(df, "rec0")
r1 = groupby_count_rename(df, "rec1")
r2 = groupby_count_rename(df, "rec2")
r3 = groupby_count_rename(df, "rec3")

# Join all columns together. The output is a table with
# item names and number of times each name appears in each rec column.
joined_df = r0.join(r1, r0.item == r1.item, 'outer') \
              .join(r2, r0.item == r2.item, 'outer') \
              .join(r3, r0.item == r3.item, 'outer') \
              .select(r0.item, "rec0", "rec1", "rec2", "rec3")

# Write the table to BigQuery.
joined_df.write \
  .format("bigquery") \
  .option("writeMethod", "direct") \
  .save("gcp_lakehouse_ds.user_recommendations")
