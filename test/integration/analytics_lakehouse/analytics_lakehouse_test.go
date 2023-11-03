// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package multiple_buckets

import (
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/bq"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
)

// Retry if these errors are encountered.
var retryErrors = map[string]string{
	".*does not have enough resources available to fulfill the request.  Try a different zone,.*": "Compute zone resources currently unavailable.",
	".*Error 400: The subnetwork resource*":                                                       "Subnet is eventually drained",
}

func TestAnalyticsLakehouse(t *testing.T) {
	dwh := tft.NewTFBlueprintTest(t, tft.WithRetryableTerraformErrors(retryErrors, 60, time.Minute))

	dwh.DefineVerify(func(assert *assert.Assertions) {
		dwh.DefaultVerify(assert)

		projectID := dwh.GetTFSetupStringOutput("project_id")

		region := dwh.GetTFSetupStringOutput("region")

		// Assert all Workflows ran successfully
		verifyWorkflows := func() (bool, error) {
			workflows := []string{
				"copy-data",
				"project-setup",
			}

			for _, workflow := range workflows {
				executions := gcloud.Runf(t, "workflows executions list %s --project %s --sort-by=~endTime", workflow, projectID).Array()
				state := executions[0].Get("state").String()
				assert.NotEqual(t, state, "FAILED")
				if state == "SUCCEEDED" {
					continue
				} else {
					return false, nil
				}
			}
			return true, nil
		}
		utils.Poll(t, verifyWorkflows, 600, 30*time.Second)

		// Assert BigQuery tables are not empty
		tables := []string{
			"gcp_lakehouse_ds.agg_events",
			"gcp_primary_raw.ga4_obfuscated_sample_ecommerce_images",
			"gcp_primary_raw.textocr_images",
			"gcp_primary_staging.new_york_taxi_trips_tlc_yellow_trips_2022",
			"gcp_primary_staging.thelook_ecommerce_distribution_centers",
			"gcp_primary_staging.thelook_ecommerce_events",
			"gcp_primary_staging.thelook_ecommerce_inventory_items",
			"gcp_primary_staging.thelook_ecommerce_order_items",
			"gcp_primary_staging.thelook_ecommerce_orders",
			"gcp_primary_staging.thelook_ecommerce_products",
			"gcp_primary_staging.thelook_ecommerce_users",
		}

		for _, table := range tables {
			op := bq.Runf(t, `query --nouse_legacy_sql
			'select
				count(*) as count
			from
				%s.%s';`, projectID, table)

			count := op.Get("count").Int()
			assert.Greater(t, count, 0, fmt.Sprintf("Table `%s` is empty.", table))
		}

		// Assert only one Dataproc cluster is available
		currentComputeInstances := gcloud.Runf(t, "dataproc clusters list --project=%s --region=%s", projectID, region).Array()
		assert.Equal(t, len(currentComputeInstances), 1, "More than one Dataproc cluster is available.")

		// Assert Dataproc cluster is stopped
		phsName := currentComputeInstances[0].Get("clusterName")
		cluster := gcloud.Runf(t, "dataproc clusters describe %s --project=%s", phsName, projectID)
		state := cluster.Get("status").Get("state").String()
		assert.Equal(t, state, "TERMINATED", "PHS is not in a stopped state")

	})

	dwh.DefineTeardown(func(assert *assert.Assertions) {

		projectID := dwh.GetTFSetupStringOutput("project_id")

		verifyNoVMs := func() (bool, error) {
			currentComputeInstances := gcloud.Runf(t, "compute instances list --project %s", projectID).Array()
			// There should only be 1 compute instance (Dataproc PHS). Wait to destroy if other instances exist.
			if len(currentComputeInstances) > 1 {
				return true, nil
			}
			return false, nil
		}
		utils.Poll(t, verifyNoVMs, 120, 30*time.Second)

		dwh.DefaultTeardown(assert)

	})
	dwh.Test()
}
