# Simple Example

This example illustrates how to use the `` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| call\_workflows\_create\_iceberg\_table | Output of the iceberg tables workflow |
| call\_workflows\_create\_views\_and\_others | Output of the create view workflow |
| workflow\_return\_bucket\_copy | Output of the bucket copy workflow |
| workflow\_return\_create\_bq\_tables | Output of the create bigquery tables workflow |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure
