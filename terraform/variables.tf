variable "gcp_project_id" {
  type        = string
  description = "Your Google Cloud Project ID."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region to deploy resources in (e.g., europe-west2 for UK)."
}

variable "gcp_zone" {
  type        = string
  description = "The GCP zone for the VM (e.g., europe-west2-a)."
}

variable "gateway_image_local_path" {
  type        = string
  description = "The local path to your downloaded OpsRamp image file."
}

variable "gateway_bucket_name" {
  type        = string
  description = "A unique name for the GCS bucket to store the image."
}

variable "gateway_vm_name" {
  type        = string
  description = "The name for the OpsRamp Gateway VM."
}

# NEW: The name of the VPC network to deploy into.
variable "vpc_network_name" {
  type        = string
  description = "The name of the VPC network to use (e.g., 'default' or 'my-custom-vpc')."
}

# NEW: List of ports for the firewall rule.
variable "gateway_firewall_ports" {
  type        = list(string)
  description = "The list of TCP ports to open for the gateway."
}
