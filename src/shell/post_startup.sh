#!/bin/bash
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


# Retrieve current project and location using gcloud
PROJECT=$(gcloud config get-value project)
ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
LOCATION="$(echo "$ZONE" | awk -F/ '{split($4, a, "-"); print a[1]"-"a[2]}')"
echo "Current instance location: $LOCATION"

# Specify the file name
YAML_FILE="temp.yaml"
NOTEBOOK="spark_ml.ipynb"

# Define the content for the YAML file
YAML_CONTENT=$(cat <<EOF
environmentConfig:
  executionConfig:
    subnetworkUri: dataproc-subnet
  peripheralsConfig: {}
jupyterSession:
  kernel: PYTHON
  displayName: SparkML Notebook
description: Serverless Template for the SparkML Notebook
labels:
  client: dataproc-jupyter-plugin
runtimeConfig:
  version: '2.2'
EOF
)

# Write the content to the YAML file
echo "$YAML_CONTENT" > /home/jupyter/"$YAML_FILE"

# Specify the GitHub repository URL and the file path
REPO_URL="https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/main/src/ipynb/spark_ml.ipynb"

# Use wget to download the file and check if the download was successful
if wget "$REPO_URL" -O /home/jupyter/"$NOTEBOOK"; then
    echo "File downloaded successfully."
else
    echo "Error downloading the file."
fi

# Import Dataproc session template
gcloud beta dataproc session-templates import sparkml-template \
  --source=/home/jupyter/"$YAML_FILE" --project="$PROJECT" --location="$LOCATION" --quiet

# Delete temporal YAML config file
rm /home/jupyter/"$YAML_FILE"
