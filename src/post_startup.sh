#!/bin/bash

# Retrieve current project and location using gcloud
PROJECT=$(gcloud config get-value project)
ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
LOCATION=$(echo $ZONE | awk -F/ '{split($4, a, "-"); print a[1]"-"a[2]}')
echo "Current instance location: $LOCATION"

TODAY=$(date +"%Y%m%d%H%M")

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
  displayName: SparkML Notebook - "$TODAY"
description: Serverless Template for the SparkML Notebook
labels:
  client: dataproc-jupyter-plugin
runtimeConfig:
  version: '2.1'
EOF
)

# Write the content to the YAML file
echo "$YAML_CONTENT" > /home/jupyter/"$YAML_FILE"

# Specify the GitHub repository URL and the file path
REPO_URL="https://raw.githubusercontent.com/hyunuk/terraform-google-analytics-lakehouse/serverless-spark-neos/src/ipynb/spark_ml.ipynb"

# Use wget to download the file
wget "$REPO_URL" -O /home/jupyter/"$NOTEBOOK"

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "File downloaded successfully."
else
    echo "Error downloading the file."
fi

# Import Dataproc session template
gcloud beta dataproc session-templates import hyunuk-test-temp \
  --source=/home/jupyter/"$YAML_FILE" --project="$PROJECT" --location="$LOCATION" --quiet

# Delete temporal YAML config file
rm /home/jupyter/"$YAML_FILE"
