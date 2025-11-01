terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.9.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# --- Step 0: Enable Required APIs ---
resource "google_project_service" "compute_api" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  project            = var.gcp_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}


## --- Step 1: Upload the Gateway Image to GCS ---
# This bucket is for the gateway .tar.gz image
resource "google_storage_bucket" "image_bucket" {
  name                          = var.gateway_bucket_name
  location                      = var.gcp_region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "image_archive" {
  name   = "images/${var.gateway_image_local_path}"
  bucket = google_storage_bucket.image_bucket.name
  source = var.gateway_image_local_path
}

## --- Step 2: Create a Custom Compute Image ---
resource "google_compute_image" "opsramp_gateway_image" {
  name = "opsramp-gateway-image"
  
  raw_disk {
    source = google_storage_bucket_object.image_archive.self_link
  }
  
  depends_on = [google_storage_bucket_object.image_archive]
}

## --- Step 3: Configure Networking & Firewall ---

# UPDATED: This now reads the network name from your variable
data "google_compute_network" "main_vpc" {
  name = var.vpc_network_name
}

# UPDATED: This now reads the port list from your variable
resource "google_compute_firewall" "allow_gateway_access" {
  name    = "allow-opsramp-gateway-access"
  network = data.google_compute_network.main_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = var.gateway_firewall_ports # e.g., ["22", "5480", "3128"]
  }
  
  source_ranges = ["0.0.0.0/0"] # TODO: Restrict this to your IP
  target_tags   = [var.gateway_vm_name]
}

## --- Step 4: Deploy the VM Instance ---
resource "google_compute_instance" "opsramp_gateway" {
  name         = var.gateway_vm_name
  machine_type = "e2-standard-2"
  zone         = var.gcp_zone
  tags         = [var.gateway_vm_name]

  boot_disk {
    initialize_params {
      image = google_compute_image.opsramp_gateway_image.self_link
      size  = 60
    }
  }

  network_interface {
    network = data.google_compute_network.main_vpc.self_link
    access_config {
      // Ephemeral public IP
    }
  }
  
  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_image.opsramp_gateway_image]
}

## --- Step 5: Output the VM's IP Address ---
output "gateway_ip_address" {
  description = "The public IP address of the OpsRamp Gateway."
  value       = google_compute_instance.opsramp_gateway.network_interface[0].access_config[0].nat_ip
}

output "gateway_activation_url" {
  description = "The URL for the gateway's web UI to complete setup."
  value       = "https://${google_compute_instance.opsramp_gateway.network_interface[0].access_config[0].nat_ip}:5480"
}
