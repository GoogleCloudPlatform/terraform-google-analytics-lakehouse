# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "bucket_name" {
  type        = string
  description = "Bucket where source data is stored"
  default     = "da-solutions-assets-1484658051840"
}
variable "region" {
  type        = string
  description = "Google Cloud Region"
  default     = "us-central1"
}

variable "dataset_id" {
  type        = string
  description = "Google Cloud BQ Dataset ID"
  default     = "gcp"
}


variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
  default     = { "edw-bigquery" = true }
}

variable "enable_apis" {
  type        = string
  description = "Whether or not to enable underlying apis in this solution. ."
  default     = true
}

variable "force_destroy" {
  type        = string
  description = "Whether or not to protect BigQuery resources from deletion when solution is modified or changed."
  default     = false
}

variable "deletion_protection" {
  type        = string
  description = "Whether or not to protect GCS resources from deletion when solution is modified or changed."
  default     = true
}

variable "use_case_short" {
  type        = string
  description = "Short name for use case"
  default     = "lakehouse"
}

variable "public_data_bucket" {
  type        = string
  description = "Public Data bucket for access"
  default     = "da-solutions-assets-1484658051840"
}