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
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
)

// Retry if these errors are encountered.
var retryErrors = map[string]string{
	// IAM for Eventarc service agent is eventually consistent
	".*Permission denied while using the Eventarc Service Agent.*": "Eventarc Service Agent IAM is eventually consistent",
	".*Error 400: The subnetwork resource*":                        "Subnet is eventually drained",
}

func TestAnalyticsLakehouse(t *testing.T) {
	dwh := tft.NewTFBlueprintTest(t, tft.WithRetryableTerraformErrors(retryErrors, 60, time.Minute))

	dwh.DefineVerify(func(assert *assert.Assertions) {
		dwh.DefaultVerify(assert)

		// TODO: Add additional asserts for other resources
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
