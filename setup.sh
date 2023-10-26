#!/bin/bash

set -eu

# Should this script error, print out the line that was responsible
_error_report() {
  echo >&2 "Exited [$?] at line $(caller):"
  cat -n $0 | tail -n+$(($1 - 3)) | head -n7 | sed "4s/^\s*/>>> /"
}
trap '_error_report $LINENO' ERR

# Check if terraform.tfvars exists and read project name and region if available
if [ -f terraform.tfvars ]; then
  echo -e "\n\xe2\x88\xb4 Found terraform.tfvars. Store variables from the file. "
  # Read project name and region from terraform.tfvars
  TF_PROJECT=$(grep -Po '(?<=project_id = ")[^"]*' terraform.tfvars)
  REGION=$(grep -Po '(?<=region = ")[^"]*' terraform.tfvars)
else
  # Check if there are arguments and they have the correct format
  if [ $# -ne 5 ]; then
    echo "Usage: $0 project_id=string region=string enable_apis=boolean force_destroy=boolean deletion_protection=boolean"
    exit 1
  fi
  
  # Define an array of expected keys
  EXPECTED_KEYS=("project_id" "region" "enable_apis" "force_destroy" "deletion_protection")

  # Check if arguments have the correct format and keys
  for arg in "$@"; do
    IFS="=" read -r key value <<< "$arg"    
    
    if [[ ! " ${EXPECTED_KEYS[@]} " =~ " $key " || ! "$arg" =~ ^[a-zA-Z_][a-zA-Z0-9_]*=.*$ ]]; then
      echo "Arguments must be in the format: key=value and the key must be either of 'project_id', 'region', 'enable_apis', 'force_destroy', 'deletion_protection'"
      exit 1
    fi
  done

  # Create terraform.tfvars.
  cat <<EOL > terraform.tfvars
# This is an example of the terraform.tfvars file.
# The values in this file must match the variable types declared in variables.tf.
# The values in this file override any defaults in variables.tf.
EOL

  # Loop through the command-line arguments
  for arg in "$@"; do
    # Split the argument into key and value using '=' as the delimiter
    IFS="=" read -r key value <<< "$arg"

    # Check if key is not empty and has a valid comment
    case "$key" in
      "project_id")
        comment="ID of the project in which you want to deploy the solution"
        TF_PROJECT=$value
        value="\"$value\""
        ;;
      "region")
        comment="Google Cloud region where you want to deploy the solution"$'\n'"# Example: us-central1"
        REGION=$value
        value="\"$value\""
        ;;
      "enable_apis")
        comment="Whether or not to enable underlying APIs in this solution"$'\n'"# Example: true"
        ;;
      "force_destroy")
        comment="Whether or not to protect BigQuery resources from deletion when the solution is modified or changed"$'\n'"# Example: false"
        ;;
      "deletion_protection")
        comment="Whether or not to protect Cloud Storage resources from deletion when the solution is modified or changed"$'\n'"# Example: true"
        ;;
      *)
        comment=""
        ;;
    esac

    # Write the key, value, and comment to terraform.tfvars
    echo "" >> terraform.tfvars
    if [ -n "$comment" ]; then
      echo "# $comment" >> terraform.tfvars
    fi
    echo "$key = $value" >> terraform.tfvars
  done

  echo -e "\n\xe2\x88\xb4 terraform.tfvars has been created with the provided values and comments."
fi

# Check if backend.tf exists and create a new one if it isn't.
if [ ! -f backend.tf ]; then
  echo -e "\n\xe2\x88\xb4 backend.tf has been created. "
  # Create terraform.tfvars.
  cat <<EOL > backend.tf
terraform {
    backend "gcs" {
    }
}
EOL
fi

# Set variables
CLOUDBUILD_SERVICE_ACCOUNT=$(gcloud projects list --format='value(PROJECT_NUMBER)' --filter=PROJECT_ID=${TF_PROJECT})@cloudbuild.gserviceaccount.com
STATE_GCS_BUCKET_NAME="${TF_PROJECT}-tf-states"

# Define the list of roles to grant for the service account
ROLES=(
  "roles/serviceusage.serviceUsageAdmin"
  "roles/iam.serviceAccountAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/config.admin"
  "roles/bigquery.admin"
  "roles/dataplex.admin"
  "roles/compute.networkAdmin"
  "roles/workflows.admin"
  "roles/compute.securityAdmin"
  "roles/dataproc.admin"
  "roles/iam.serviceAccountUser"
  "roles/storage.admin"
)

# Services needed for Terraform to manage resources via service account 
echo -e "\n\xe2\x88\xb4 Enabling initial required services... "
gcloud services enable --project $TF_PROJECT \
    iamcredentials.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    serviceusage.googleapis.com \
    appengine.googleapis.com \
    cloudbuild.googleapis.com > /dev/null

# Grant each role to the service account
for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding ${TF_PROJECT} \
    --member="serviceAccount:${CLOUDBUILD_SERVICE_ACCOUNT}" \
    --role=${ROLE} > /dev/null 2>&1
done

# Setup Terraform state bucket
if gcloud storage buckets list gs://${STATE_GCS_BUCKET_NAME} --project ${TF_PROJECT} &> /dev/null ; then
  echo -e "\n\xe2\x88\xb4 Using existing Terraform remote state bucket: gs://${STATE_GCS_BUCKET_NAME} "
else
  echo -e "\n\xe2\x88\xb4 Creating Terraform remote state bucket: gs://${STATE_GCS_BUCKET_NAME} "
  gcloud storage buckets create gs://${STATE_GCS_BUCKET_NAME} --project=${TF_PROJECT} --location=${REGION} > /dev/null
fi

echo -e "\n\xe2\x88\xb4 Enabling versioning... "
gcloud storage buckets update gs://${STATE_GCS_BUCKET_NAME} --versioning --project ${TF_PROJECT} > /dev/null

# Run cloud build
gcloud builds submit ./ --project=${TF_PROJECT} \
    --config=./src/yaml/terraform.cloudbuild.yaml \
    --substitutions=_STATE_GCS_BUCKET_NAME=$STATE_GCS_BUCKET_NAME
