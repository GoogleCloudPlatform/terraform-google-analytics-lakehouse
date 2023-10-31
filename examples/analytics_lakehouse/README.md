# Analytics Lakehouse Example

This example illustrates how to use the `analytics_lakehouse` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bigquery\_editor\_url | The URL to launch the BigQuery editor |
| lakehouse\_colab\_url | The URL to launch the Colab instance |
| lookerstudio\_report\_url | The URL to create a new Looker Studio report |
| region | The Compute region where resources are created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure
