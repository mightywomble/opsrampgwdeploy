
# HPE OpsRamp Gateway Deployment on GCP with Terraform

This repository contains Terraform code to automatically deploy an HPE OpsRamp Gateway on the Google Cloud Platform (GCP).

> Before you begin: configure Terraform remote state (GCS backend)
>
> Terraform stores its state in a Google Cloud Storage (GCS) bucket. The backend in `terraform/backend.tf` points to that bucket but does not create it. Do this once per project/environment:
>
> 1. Choose a globally unique bucket name for state, e.g. `opsramp-tfstate-<project>-<env>`.
> 2. Create the bucket (any region is fine; use one close to you):
>
>    Bash
>
>    ```
>    gcloud storage buckets create gs://<STATE_BUCKET> \
>      --project <PROJECT_ID> \
>      --location <REGION> \
>      --uniform-bucket-level-access
>    ```
>
>    (Alternative) Using gsutil:
>
>    ```
>    gsutil mb -b on -l <REGION> gs://<STATE_BUCKET>
>    ```
>
> 3. Edit `terraform/backend.tf` and set:
>
>    ```
>    bucket = "<STATE_BUCKET>"
>    # keep: prefix = "opsramp/gateway"
>    ```
>
> 4. From the `terraform/` directory, initialize or reconfigure the backend:
>
>    ```
>    terraform init -reconfigure
>    ```
>
It automates the entire process of:

1.  Creating a GCS bucket.
    
2.  Uploading the OpsRamp Gateway image (`.tar.gz`).
    
3.  Creating a custom GCP Compute Image from the uploaded file.
    
4.  Deploying a VM instance from that custom image.
    
5.  Configuring the necessary firewall rules.
    

## 🤔 Why Use This?

The standard manual process for deploying the OpsRamp Gateway involves many steps in the GCP console. This Terraform code automates that process, making it **repeatable, auditable, and much faster**.

This allows you to deploy a new gateway in minutes with just one command.

## 📋 Prerequisites

Before you can run this code, you must:

1.  Have **Terraform** installed.
    
2.  Have the **`gcloud` CLI** installed and authenticated (run `gcloud auth application-default login`).
    
3.  **Download the OpsRamp Gateway image** (e.g., `OpsRampGateway.tar.gz`) from your OpsRamp portal.
    
4.  **Copy your OpsRamp Activation Token** from the OpsRamp portal (**Setup > Resources > Management Profiles**).
    

----------

## 🚀 How to Run

### 1. Prepare Your Files

-   Clone this repository.
    
-   Place your downloaded OpsRamp Gateway image (e.g., `OpsRampGateway.tar.gz`) in the root of this folder.
    

### 2. Configure Your Variables

-   Edit the **`terraform.tfvars`** file.
    
-   Fill in your `gcp_project_id`, a `gateway_bucket_name` (must be globally unique), and the name of your local image file.
    

### 3. Initialize Terraform

This downloads the Google provider plugin.

Bash

```
terraform init

```

### 4. Create a Plan

This is a "dry run" that shows you what Terraform _will_ do. We save this plan to an "outfile" called `tfplan`.

Bash

```
terraform plan -out=tfplan

```

-   **What is an outfile?** The `-out=tfplan` flag saves the _exact_ set of proposed changes to a binary file named `tfplan`.
    
-   **Why use it?** This is a critical best practice. It guarantees that the changes you apply are **exactly** the same as the changes you just reviewed. This prevents situations where the cloud state might change between your `plan` and `apply` steps.
    

### 5. Apply the Plan

This executes the saved plan and builds your infrastructure.

Bash

```
terraform apply "tfplan"

```

This process will take several minutes, as the OpsRamp image file is large and takes time to upload and be processed by GCP.

### 6. Activate the Gateway

Once the `apply` is complete, Terraform will output the `gateway_activation_url`:

1.  Go to the URL (e.g., `https://[VM_IP_ADDRESS]:5480`).
    
2.  Log in with the default OpsRamp gateway credentials.
    
3.  Navigate to the **Registration** page and paste in your **Activation Token** from the prerequisites.
    

----------

## 🗂️ Understanding the Files

### `variables.tf` vs `terraform.tfvars`

-   **`variables.tf`** is the **declaration file**. Think of it as a blank form that defines all the questions Terraform _needs_ to ask (like `gcp_project_id` or `gateway_vm_name`). It sets the _rules_ for each variable.
    
-   **`terraform.tfvars`** is the **definition file**. This is the _filled-out form_ where you provide the _answers_ to those questions.
    

When you run `terraform plan`, Terraform looks at `variables.tf` to see what it needs, and then automatically loads the values from `terraform.tfvars` to fill them in.

#### Why is `terraform.tfvars` the only file to edit?

This setup is by design. It separates the **reusable logic** (`main.tf`) from the **specific configuration** (`terraform.tfvars`). This allows you to reuse the same `main.tf` code for different projects (e.g., development, production) just by swapping out the `terraform.tfvars` file.

### `.gitignore`

This file tells Git which files and folders to **ignore** and _never_ commit to the repository. This is crucial for security and hygiene.

This repository's `.gitignore` ignores:

-   **`terraform.tfstate` and `terraform.tfstate.backup`**: These files contain sensitive information about your infrastructure, including potential secrets. They must never be public.
    
-   **`.terraform/`**: A local cache folder that holds the provider plugins. It's re-created by `terraform init` and is specific to your machine.
    
-   **`*.tfvars`**: It's a best practice to ignore all `.tfvars` files, as they often contain sensitive data like project IDs or keys.
    
-   **`tfplan`**: The binary plan file is temporary and specific to a single `apply`.
    
-   **`*.tar.gz`**: Your OpsRamp Gateway image is a large binary file, not source code, and should not be stored in Git.
    

----------

## 🗺️ Code Deep Dive: `main.tf` and the GCP Console

Here is a breakdown of what each resource in `main.tf` does and where you can see it in the GCP Console.

**Resource in main.tf**

**What It's Doing**

**📍 Where to See it in GCP Console**

**`google_project_service`**

Enables the Compute and Storage APIs so Terraform has permission to create resources.

**APIs & Services > Library** (Search for "Compute Engine API" to see if it's "Enabled")

**`google_storage_bucket`**

Creates a new GCS bucket to hold the gateway image.

**Cloud Storage > Buckets** (You will see a new bucket with the name you set in `terraform.tfvars`)

**`google_storage_bucket_object`**

Uploads your local `.tar.gz` file into the new bucket.

**Cloud Storage > Buckets > (Your Bucket Name)** (You'll see the `.tar.gz` file listed as an object)

**`google_compute_image`**

This is the key step. It tells GCP to read the `.tar.gz` file and "import" it as a new, bootable VM image (template).

**Compute Engine > Storage > Images** (You'll see an image named `opsramp-gateway-image` with a "Creating" status)

**`google_compute_firewall`**

Creates a firewall rule to allow web access (TCP:5480) and SSH (TCP:22) to your new gateway VM.

**VPC network > Firewall** (You'll see a rule named `allow-opsramp-gateway-access`)

**`google_compute_instance`**

Deploys the actual VM using the custom image we just created.

**Compute Engine > VM instances** (You'll see your new VM running)

**`output "gateway..._url"`**

Reads the public IP address from the created VM and formats it as a URL for you.

**Compute Engine > VM instances > (Your VM)** (Look in the **External IP** column)

----------

## 🔬 Files Created by Terraform

When you run `terraform apply`, you will see new files and folders appear.

-   **`.terraform/` directory**: This is a local cache. When you run `terraform init`, it downloads the Google provider plugin and stores it here. It is safe to delete and is ignored by Git.
    
-   **`terraform.tfstate`**: This is the **most important file**. It is Terraform's "memory" or "source of truth." It's a JSON file that maps your code (`main.tf`) to the real-world resources you created (like the VM ID, bucket name, etc.). This is how Terraform knows what it's managing.
    
-   **`terraform.tfstate.backup`**: A safety copy of your state file, created just before an `apply`, in case the state gets corrupted.
    

> **⚠️ Warning:** Never manually edit the `.tfstate` files unless you are an expert. Never, ever commit them to a public repository.

----------

## 🛠️ Troubleshooting Guide

Here are common errors you might encounter and how to fix them.

-   **Error: `SERVICE_DISABLED` (e.g., Compute Engine API)**
    
    -   **Why:** The `compute.googleapis.com` API is not enabled in your project.
        
    -   **Fix:** The `google_project_service` resource in `main.tf` is supposed to fix this automatically. If it fails (due to permissions), you can fix it manually:
        
        1.  Go to **APIs & Services > Library** in the GCP Console.
            
        2.  Search for "Compute Engine API" and click **Enable**.
            
        3.  Wait 2-3 minutes and run `terraform apply "tfplan"` again.
            
-   **Error: `403: ... does not have serviceusage.services.enable permission`**
    
    -   **Why:** The user account you authenticated with (`gcloud auth...`) does not have permission to enable APIs.
        
    -   **Fix:** In the GCP Console, go to **IAM & Admin > IAM**. Find your user account and grant it the **Service Usage Admin** (`roles/serviceusage.serviceUsageAdmin`) role.
        
-   **Error: `constraints/storage.uniformBucketLevelAccess`**
    
    -   **Why:** Your GCP project has a security policy that requires all new buckets to use "Uniform Bucket-Level Access."
        
    -   **Fix:** This is already fixed in the `main.tf` file. The `google_storage_bucket` resource includes the line `uniform_bucket_level_access = true` to satisfy this policy.
        
-   **Error: `Error creating Image... not a valid Google Cloud Storage object`**
    
    -   **Why:** This is a cloud "race condition." Terraform tried to create the image _immediately_ after uploading the file, but the Compute API couldn't "see" the newly uploaded file in the GCS bucket yet.
        
    -   **Fix:** This is fixed in `main.tf` by using `source = google_storage_bucket_object.image_archive.self_link`, which creates a stronger dependency. If you still see this, just **wait one minute and run `terraform apply "tfplan"` again.** The file will be visible, and the command will succeed.