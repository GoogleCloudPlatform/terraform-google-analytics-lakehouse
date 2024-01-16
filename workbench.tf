# Creates a service account specifically for the Workbench instance.
resource "google_service_account" "workbench_service_account" {
  project      = module.project-services.project_id
  account_id   = "workbench-sa-${random_id.id.hex}"
  display_name = "Service Account for Workbench Instance"
}

# Grants necessary roles to the Workbench service account.
resource "google_project_iam_member" "workbench_sa_roles" {
  for_each = toset([
    "roles/iam.serviceAccountUser",
    "roles/storage.objectAdmin",
    "roles/compute.osAdminLogin",
    "roles/dataproc.admin",
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workbench_service_account.email}"
}

# Provisions a new Workbench instance.
resource "google_workbench_instance" "workbench_instance" {
  name     = "gcp-${var.use_case_short}-workbench-instance-${random_id.id.hex}"
  project  = module.project-services.project_id
  location = "${var.region}-a"

  gce_setup {
    machine_type = "e2-standard-4"

    vm_image {
      project = "cloud-notebooks-managed"
      name    = "workbench-instances-v20231108-py310"
    }

    network_interfaces {
      network  = google_compute_network.default_network.id
      subnet   = google_compute_subnetwork.subnet.id
      nic_type = "GVNIC"
    }

    disable_public_ip = false

    service_accounts {
      email = google_service_account.workbench_service_account.email
    }

    metadata = {
      proxy-mode            = "service_account"
      idle-timeout-seconds  = "10800"
      report-event-health   = "true"
      disable-mixer         = "false"
      post-startup-script   = "gs://${google_storage_bucket.provisioning_bucket.name}/post_startup.sh"
      report-dns-resolution = "true"
    }

    enable_ip_forwarding = true
  }

  depends_on = [
    google_project_iam_member.workbench_sa_roles,
    google_compute_subnetwork.subnet
  ]
}
