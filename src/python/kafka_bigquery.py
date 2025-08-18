#!/usr/bin/python
# Copyright 2025 Google LLC
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

from pyspark.sql import SparkSession
from pyspark.sql.functions import struct, col, to_json
import sys

project_id = sys.argv[1]
region = sys.argv[2]
cluster_id = sys.argv[3]
topic_id = sys.argv[4]

bootstrap_url = f"bootstrap.{cluster_id}.{region}.managedkafka.{project_id}.cloud.goog:9092"

spark = SparkSession \
    .builder \
    .appName("spark-kafka") \
    .getOrCreate()


order_items_df = spark.read.format("bigquery").load(f"{project_id}.thelook_{project_id.replace('-', '_')}.order_items")

kafka_df = order_items_df.select(col("id").cast("string").alias("key"), to_json(struct(*order_items_df.columns)).alias("value"))

kafka_df \
  .write \
  .format("kafka") \
  .option("kafka.bootstrap.servers", bootstrap_url) \
  .option("topic", topic_id) \
  .option("kafka.security.protocol", "SASL_SSL") \
  .option("kafka.sasl.mechanism", "OAUTHBEARER") \
  .option("kafka.sasl.login.callback.handler.class", "com.google.cloud.hosted.kafka.auth.GcpLoginCallbackHandler") \
  .option("kafka.sasl.jaas.config", "org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required;") \
  .save()
