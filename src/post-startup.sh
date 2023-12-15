#!/bin/bash

# Get the active project id
PROJECT_ID=$(gcloud config get-value project)
echo "PROJECT_ID: $PROJECT_ID"

# Define the bucket prefix
BUCKET_PREFIX="gcp-lakehouse-"

# Use gsutil to list buckets and find the first one matching the prefix
BUCKET_NAME=$(gsutil ls | grep "$BUCKET_PREFIX" | head -n 1)

# Check if a matching bucket was found
if [ -n "$BUCKET_NAME" ]; then
    # Use gcloud to describe the bucket and extract the location
    BUCKET_LOCATION=$(gcloud storage buckets describe "$BUCKET_NAME" --format="value(location)")
    echo "Bucket location for $BUCKET_NAME is $BUCKET_LOCATION"

    # Convert the location to lowercase
    BUCKET_REGION=$(echo "$BUCKET_LOCATION" | tr '[:upper:]' '[:lower:]')
else
    echo "No bucket found with the prefix $BUCKET_PREFIX"
fi
echo "BUCKET_REGION: $BUCKET_REGION"

# Define the path for the YAML configuration file
YAML_FILE="/home/jupyter/test.yaml"

# Define the content for the YAML configuration for dataproc session
echo "$(cat <<EOF
environmentConfig:
  executionConfig:
    subnetworkUri: dataproc-subnet
jupyterSession:
  kernel: PYTHON
  displayName: SparkML Notebook
description: Serverless Template for the SparkML Notebook
labels:
  client: dataproc-jupyter-plugin
runtimeConfig:
  version: '2.1'
EOF
)" > $YAML_FILE

# Specify the GitHub repository URL and the file path
REPO_URL="https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/main/src/ipynb/spark_ml.ipynb"
OUTPUT_FILE="/home/jupyter/spark_ml.ipynb"

# Download the file using wget
if wget "$REPO_URL" -O "$OUTPUT_FILE"; then
    echo "File downloaded successfully."
else
    echo "Error downloading the file."
fi

# Define template name
TEMPLATE_NAME="SparkML"

# Create a Dataproc session template with YAML configuration
gcloud beta dataproc session-templates import "$TEMPLATE_NAME" \
  --source="$YAML_FILE" \
  --project="$PROJECT_ID" \
  --location="$BUCKET_REGION"

# Remove the YAML file
rm "$YAML_FILE"
