terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.56"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.52"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.2.1"
    }
  }
  required_version = ">= 0.13"

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-analytics-lakehouse/v1.0.0"
  }
}
