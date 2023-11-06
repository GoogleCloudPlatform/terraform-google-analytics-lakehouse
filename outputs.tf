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

output "workflow_return_project_setup" {
  description = "Output of the project setup workflow"
  value       = data.http.call_workflows_project_setup.response_body
}

output "lookerstudio_report_url" {
  value       = "https://lookerstudio.google.com/reporting/create?c.reportId=79675b4f-9ed8-4ee4-bb35-709b8fd5306a&ds.ds0.datasourceName=vw_ecommerce&ds.ds0.projectId=${var.project_id}&ds.ds0.type=TABLE&ds.ds0.datasetId=gcp_lakehouse_ds&ds.ds0.tableId=view_ecommerce"
  description = "The URL to create a new Looker Studio report displays a sample dashboard for data analysis"
}

output "bigquery_editor_url" {
  value       = "https://console.cloud.google.com/bigquery?project=${var.project_id}"
  description = "The URL to launch the BigQuery editor"
}

output "neos_tutorial_url" {
  value       = "http://console.cloud.google.com/products/solutions/deployments?walkthrough_id=panels--sic--analytics-lakehouse_toc"
  description = "The URL to launch the in-console tutorial for the Analytics Lakehouse solution"
}

output "lakehouse_colab_url" {
  value       = "https://colab.research.google.com/github/GoogleCloudPlatform/terraform-google-analytics-lakehouse/blob/main/src/ipynb/exploratory-analysis.ipynb"
  description = "The URL to launch the in-console tutorial for the Analytics Lakehouse solution"
}

output "region" {
  value       = var.region
  description = "The Compute region where resources are created."
}
