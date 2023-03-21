terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
  }
  required_version = ">= 0.13"

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-analytics-lakehouse/v1.0.0"
  }
}