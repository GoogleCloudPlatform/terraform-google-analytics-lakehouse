/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "workflow_return_bucket_copy" {
  description = "Output of the bucket copy workflow"
  value       = data.http.call_workflows_bucket_copy_run.response_body
}

output "workflow_return_create_bq_tables" {
  description = "Output of the create bigquery tables workflow"
  value       = data.http.call_workflows_create_gcp_biglake_tables_run.response_body
}

output "call_workflows_create_views_and_others" {
  description = "Output of the create view workflow"
  value       = data.http.call_workflows_create_views_and_others.response_body
}
output "call_workflows_create_iceberg_table" {
  description = "Output of the iceberg tables workflow"
  value       = data.http.call_workflows_create_iceberg_table.response_body
}
