#!/usr/bin/env bash

set -eu

# Should this script error, print out the line that was responsible
_error_report() {
  echo >&2 "Exited [$?] at line $(caller):"
  cat -n $0 | tail -n+$(($1 - 3)) | head -n7 | sed "4s/^\s*/>>> /"
}
trap '_error_report $LINENO' ERR

# Set variables
TF_PROJECT=$(gcloud config get-value project)
TF_PROJECT_NUMBER=$(gcloud projects list --format='value(PROJECT_NUMBER)' --filter=PROJECT_ID=$TF_PROJECT)
CLOUDBUILD_SERVICE_ACCOUNT=${TF_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com

# The service account that will impersonate in the Terraform
export TF_SERVICE_ACCOUNT=terraformer@${TF_PROJECT}.iam.gserviceaccount.com
# GCS bucket to store Terraform states
export STATE_GCS_BUCKET_NAME="$TF_PROJECT-tf-states"

# IAM permissions that are needed for Terraform SA
TF_IAM="bindings:
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/cloudbuild.builds.editor
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/config.admin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/iam.serviceAccountAdmin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/resourcemanager.projectIamAdmin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/serviceusage.serviceUsageAdmin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/bigquery.admin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/dataplex.admin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/compute.networkAdmin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/storage.admin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/workflows.admin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/iam.serviceAccountUser
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/compute.securityAdmin
- members:
  - serviceAccount:${TF_SERVICE_ACCOUNT}
  role: roles/dataproc.admin"


# Services needed for Terraform to manage resources via service account 
echo -e "\n\xe2\x88\xb4 Enabling initial required services... "
gcloud services enable --project $TF_PROJECT \
    iamcredentials.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    serviceusage.googleapis.com \
    appengine.googleapis.com \
    cloudbuild.googleapis.com > /dev/null

# Create terraform service account
if gcloud iam service-accounts describe \
    $TF_SERVICE_ACCOUNT \
    --project $TF_PROJECT &> /dev/null ; then
        echo -e "\n\xe2\x88\xb4 Using existing Terraform service account:  $TF_SERVICE_ACCOUNT "
else
    echo -e "\n\xe2\x88\xb4 Creating a new Terraform service account: $TF_SERVICE_ACCOUNT "
    gcloud iam service-accounts create terraformer \
        --project="$TF_PROJECT" \
        --description="Service account for deploying resources via Terraform" \
        --display-name="Terraformer"
fi

# Give cloud build service account token creator on terraform service account policy
echo -e "\n\xe2\x88\xb4 Updating Terraform service account IAM policy... "
gcloud iam service-accounts add-iam-policy-binding --project=$TF_PROJECT \
    $TF_SERVICE_ACCOUNT \
    --member="serviceAccount:${CLOUDBUILD_SERVICE_ACCOUNT}" \
    --role="roles/iam.serviceAccountTokenCreator" &> /dev/null

# Give permissions
echo -e "\n\xe2\x88\xb4 Updating Terraform project IAM policy... "
CURRENT_IAM=$(gcloud projects get-iam-policy $TF_PROJECT --format=yaml | tail -n +2)
echo -e "${TF_IAM}\n${CURRENT_IAM}" | \
    gcloud projects set-iam-policy $TF_PROJECT /dev/stdin > /dev/null

# Setup Terraform state bucket
if gcloud storage buckets list gs://$STATE_GCS_BUCKET_NAME --project $TF_PROJECT &> /dev/null ; then
    echo -e "\n\xe2\x88\xb4 Using existing Terraform remote state bucket: gs://${STATE_GCS_BUCKET_NAME} "
    gcloud storage buckets update gs://$STATE_GCS_BUCKET_NAME --versioning --project $TF_PROJECT > /dev/null
else
    echo -e "\n\xe2\x88\xb4 Creating Terraform remote state bucket: gs://${STATE_GCS_BUCKET_NAME} "
    gcloud storage buckets create gs://${STATE_GCS_BUCKET_NAME} --project=$TF_PROJECT > /dev/null
    echo -e "\n\xe2\x88\xb4 Enabling versioning... "
    gcloud storage buckets update gs://$STATE_GCS_BUCKET_NAME --versioning --project $TF_PROJECT > /dev/null
fi

echo -e "\n\xe2\x88\xb4 Setting storage bucket IAM policy for Terraform service account..."
gsutil iam ch serviceAccount:${TF_SERVICE_ACCOUNT}:admin \
  gs://${STATE_GCS_BUCKET_NAME}

# run cloud build
gcloud builds submit ./ --project=$TF_PROJECT \
    --config=./src/yaml/terraform.cloudbuild.yaml \
    --substitutions=_STATE_GCS_BUCKET_NAME=$STATE_GCS_BUCKET_NAME,_TF_SERVICE_ACCT=$TF_SERVICE_ACCOUNT

# how to delete?
