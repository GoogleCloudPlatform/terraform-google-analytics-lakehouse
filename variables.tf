# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable project_id {
  type        = string
  description = "Google Cloud Project ID"
}
variable bucket_name {
  type        = string
  description = "Bucket where source data is stored"
  default     = "da-solutions-assets-1484658051840"
}
variable region {
  type        = string
  description = "Google Cloud Region"
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
