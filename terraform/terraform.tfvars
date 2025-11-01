# --- GCP Project and Location (UK) ---
gcp_project_id = "cudo-infra-team"
gcp_region     = "europe-west2"
gcp_zone       = "europe-west2-a"

# --- OpsRamp Gateway Configuration ---
gateway_image_local_path = "OpsRampGateway.tar.gz"
gateway_bucket_name      = "opsramp-gateway-vm-norwaydc-30102025"
gateway_vm_name          = "opsramp-gateway-vm-norwaydc"

# The name of the VPC network to deploy into.
# (This fixed your "projects/.../networks/default not found" error)
vpc_network_name = "your-actual-network-name"

# The ports to open. Port 3128 has been added.
gateway_firewall_ports = ["22", "5480", "3128"]
