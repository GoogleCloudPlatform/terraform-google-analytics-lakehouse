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

		time.Sleep(300 * time.Second)

		projectID := dwh.GetTFSetupStringOutput("project_id")

		verifyWorkflow := func(workflow string) (bool, error) {
			executions := gcloud.Runf(t, "workflows executions list %s --project %s --sort-by=startTime", workflow, projectID)
			state := executions.Get("0.state").String()
			if state == "FAILED" {
				id := executions.Get("0.name")
				gcloud.Runf(t, "workflows executions describe %s", id)
				t.FailNow()
			}
			if state == "SUCCEEDED" {
				return false, nil
			}
			return true, nil
		}

		// Assert copy-data workflow ran successfully
		verifyCopyDataWorkflow := func() (bool, error) {
			return verifyWorkflow("copy-data")
		}
		utils.Poll(t, verifyCopyDataWorkflow, 50, 15*time.Second)

		// Assert project-setup workflow ran successfully
		verifyProjectSetupWorkflow := func() (bool, error) {
			return verifyWorkflow("project-setup")
		}
		utils.Poll(t, verifyProjectSetupWorkflow, 100, 15*time.Second)
	})

	dwh.DefineTeardown(func(assert *assert.Assertions) {
		dwh.DefaultTeardown(assert)

	})
	dwh.Test()
}
