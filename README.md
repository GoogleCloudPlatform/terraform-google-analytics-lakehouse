# terraform-google-lakehouse

## Description
### tagline
This is an auto-generated module.

### detailed
This module was generated from [terraform-google-module-template](https://github.com/terraform-google-modules/terraform-google-module-template/), which by default generates a module that simply creates a GCS bucket. As the module develops, this README should be updated.

The resources/services/activations/deletions that this module will create/trigger are:

- Create a GCS bucket with the provided name

### preDeploy
To deploy this blueprint you must have an active billing account and billing permissions.

## Documentation
- [Hosting a Static Website](https://cloud.google.com/storage/docs/hosting-static-website)

## Usage

Basic usage of this module is as follows:

```hcl
module "" {
  source  = "terraform-google-modules//google"
  version = "~> 0.1"

  project_id  = "<PROJECT ID>"
  bucket_name = "gcs-test-bucket"
}
```

Functional examples are included in the
[examples](./examples/) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deletion\_protection | Whether or not to protect GCS resources from deletion when solution is modified or changed. | `string` | `true` | no |
| enable\_apis | Whether or not to enable underlying apis in this solution. . | `string` | `true` | no |
| force\_destroy | Whether or not to protect BigQuery resources from deletion when solution is modified or changed. | `string` | `true` | no |
| labels | A map of labels to apply to contained resources. | `map(string)` | <pre>{<br>  "edw-bigquery": true<br>}</pre> | no |
| project\_id | Google Cloud Project ID | `string` | n/a | yes |
| public\_data\_bucket | Public Data bucket for access | `string` | `"data-analytics-demos"` | no |
| region | Google Cloud Region | `string` | `"us-central1"` | no |
| use\_case\_short | Short name for use case | `string` | `"lakehouse"` | no |

## Outputs

| Name | Description |
|------|-------------|
| call\_workflows\_create\_iceberg\_table | Output of the iceberg tables workflow |
| call\_workflows\_create\_views\_and\_others | Output of the create view workflow |
| workflow\_return\_bucket\_copy | Output of the bucket copy workflow |
| workflow\_return\_create\_bq\_tables | Output of the create bigquery tables workflow |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- Storage Admin: `roles/storage.admin`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Storage JSON API: `storage-api.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
