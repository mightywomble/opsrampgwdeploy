# This new file configures Terraform to save its state file in a GCS bucket.
#
# IMPORTANT: This block CANNOT use variables. You must:
# 1. Create a GCS bucket manually (e.g., "my-project-tf-state-bucket").
# 2. Edit the "bucket" line below with that bucket's name.

terraform {
  backend "gcs" {
    bucket = "YOUR-PRE-EXISTING-STATE-BUCKET-NAME-HERE"
    prefix = "opsramp/gateway" # This is the "location" (folder) in the bucket
  }
}