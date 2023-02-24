# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable project_id {
  type        = string
  description = "Google Cloud Project ID"
}

variable big_lake_bucket_project_id {
  type        = string
  description = "Project thats hosts biglake data in buckets"
  default = "solutions-2023-testing-c"
}

variable bucket_name {
  type        = string
  description = "Bucket where source data is stored"
  default     = "da-solutions-assets-1484658051840-sandbox"
}
variable region {
  type        = string
  description = "Google Cloud Region"
  default = "us-central1"
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
