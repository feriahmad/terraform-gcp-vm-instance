# Terraform GCP VM Instance Configuration

This Terraform configuration creates a setup of 3 VM instances in Google Cloud Platform (GCP) with the following specifications:

- Project ID: polished-tube-312806
- Region: us-central1
- 3 VM instances with e2-small specification
- 1 VPC network with a subnet
- 1 VM with static public IP, the other 2 with only internal connectivity
- All VMs accessible via SSH public key authentication
- The VM with public IP allows access on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS)

## Architecture

```
                                  +-------------------+
                                  |                   |
                                  |  Internet         |
                                  |                   |
                                  +--------+----------+
                                           |
                                           | Public IP
                                           |
                                  +--------v----------+
                                  |                   |
                                  |  public-vm        |
                                  |  (e2-small)       |
                                  |                   |
                                  +--------+----------+
                                           |
                                           | Internal Network (10.0.0.0/24)
                                           |
                     +--------------------+v+--------------------+
                     |                                           |
        +------------v-----------+              +---------------v------------+
        |                        |              |                            |
        |  private-vm-1          |              |  private-vm-2              |
        |  (e2-small)            |              |  (e2-small)                |
        |                        |              |                            |
        +------------------------+              +----------------------------+
```

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Google Cloud SDK installed and configured
3. Terraform installed (version 0.12+)
4. SSH key pair generated (if not already available)

## Setup

1. Clone this repository or copy the Terraform files to your local machine.
2. Authenticate with Google Cloud and set the correct project:
   ```bash
   # Login to Google Cloud
   gcloud auth login

   # Set the project
   gcloud config set project polished-tube-312806

   # Create application default credentials for Terraform
   gcloud auth application-default login
   ```
3. Update the `terraform.tfvars` file with your specific values if needed.
4. Make sure your SSH public key is available at the path specified in `terraform.tfvars` (default: `~/.ssh/id_rsa.pub`).

## Usage

### Initialize Terraform

```bash
terraform init
```

### Preview the changes

```bash
terraform plan
```

### Apply the configuration

```bash
terraform apply
```

When prompted, type `yes` to confirm the creation of resources.

### Access the VMs

After the resources are created, Terraform will output the IP addresses of the VMs.

To access the public VM:

```bash
ssh admin@<public_vm_external_ip>
```

To access the private VMs, you need to SSH to the public VM first, then SSH to the private VMs using their internal IPs:

```bash
# From the public VM
ssh admin@<private_vm_internal_ip>
```

### Clean up

To destroy all resources created by Terraform:

```bash
terraform destroy
```

When prompted, type `yes` to confirm the deletion of resources.

## CI/CD with Terraform and Atlantis

This repository is configured with a GitHub Actions workflow that integrates Terraform with Atlantis for automated infrastructure management. The workflow uses the official Atlantis Docker image to run Atlantis commands directly in response to pull requests and comments.

### How it works

1. When you create a pull request that modifies Terraform files (*.tf, *.tfvars), the workflow automatically runs Atlantis autoplan and posts the results as a comment on the PR.
2. You can use the following Atlantis commands in PR comments:
   ```
   atlantis plan           # Generate a new plan
   atlantis apply          # Apply the current plan
   atlantis unlock <id>    # Unlock the Terraform state with the specified lock ID
   atlantis approve_policies # Approve any policy checks
   atlantis version        # Show the Atlantis version
   atlantis help           # Show help information
   ```
3. Example usage:
   ```
   # To run a plan
   atlantis plan
   
   # To apply changes
   atlantis apply
   
   # To unlock a state
   atlantis unlock 1234abcd-ef56-7890
   ```
4. The workflow runs the Atlantis Docker container with your specified command and captures the output.
5. After processing the command, the workflow posts a comment on the PR with the results, including the full output from Atlantis.

The GitHub Actions workflow is configured to respond to comments containing Atlantis commands, providing the same experience as a dedicated Atlantis server but without requiring a separate server deployment. It uses the official Atlantis Docker image to ensure compatibility and consistent behavior with standard Atlantis deployments.

### Infracost Integration

Cost estimates for infrastructure changes are provided by the Infracost GitHub app integration. This integration automatically adds cost estimates to pull requests, helping you understand the financial impact of your Terraform modifications before applying them.

The provider configuration in `main.tf` has been set up with an alias, and all resources explicitly use this provider to ensure compatibility with various tools:

```hcl
# Configure the Google Cloud provider with an alias
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  alias   = "main"
}

# Example resource using the aliased provider
resource "google_compute_network" "vpc_network" {
  provider                = google.main
  name                    = "terraform-network"
  auto_create_subnetworks = false
}
```

### GitHub Secrets Required

For the Atlantis GitHub Actions workflow to function properly, you need to set up the following secrets in your GitHub repository:

- `GCP_SA_KEY`: The JSON key of a GCP service account with appropriate permissions for the resources in your Terraform configuration. This is passed to the Atlantis Docker container as the `GOOGLE_CREDENTIALS` environment variable.
- `GCP_PROJECT_ID`: Your Google Cloud project ID. This is passed to the Atlantis Docker container as the `TF_VAR_project_id` environment variable.
- `GITHUB_TOKEN`: This is automatically provided by GitHub Actions and is used by Atlantis to comment on PRs and interact with the GitHub API.
- `SSH_PUBLIC_KEY` (optional): Your SSH public key for VM access. If not provided, a dummy key will be used in CI/CD environments.

You can use the provided `setup-github-secrets.sh` script to help you create a GCP service account and set up the required GitHub secrets:

```bash
# Make the script executable
chmod +x setup-github-secrets.sh

# Run the script
./setup-github-secrets.sh
```

The script will guide you through the process of:
1. Creating a GCP service account with the necessary permissions
2. Generating a service account key
3. Setting up the GitHub secret (if GitHub CLI is installed) or providing instructions for manual setup

Note: The generated `gcp-sa-key.json` file is automatically added to `.gitignore` to prevent accidentally committing sensitive credentials to your repository. Always ensure this file is not pushed to version control.

### Local Atlantis Setup (Optional)

If you want to run Atlantis locally for testing:

1. Install Atlantis: https://www.runatlantis.io/docs/installation.html
2. Run Atlantis with:
   ```bash
   atlantis server \
     --repo-allowlist="github.com/your-username/terraform-gcp-vm-instance" \
     --gh-user="your-github-username" \
     --gh-token="your-github-token" \
     --gh-webhook-secret="your-webhook-secret"
   ```
3. Set up a webhook in your GitHub repository pointing to your Atlantis server.

## Files

- `main.tf`: Main Terraform configuration file
- `variables.tf`: Variable definitions
- `outputs.tf`: Output definitions
- `terraform.tfvars`: Variable values
- `atlantis.yaml`: Atlantis configuration file
- `.github/workflows/atlantis.yml`: GitHub Actions workflow for Terraform with Atlantis comment-based operations
- `setup-github-secrets.sh`: Helper script to set up GitHub secrets for CI/CD

## Notes

- The default SSH username is set to `admin` and can be changed in the `terraform.tfvars` file.
- SSH key configuration:
  - For local development: The default SSH public key path is set to `~/.ssh/id_rsa.pub` and can be changed in the `terraform.tfvars` file.
  - For CI/CD: A dummy SSH key is automatically set in the GitHub Actions workflow. In production, you should set a real SSH key using a secure method.
- The firewall rules allow SSH, HTTP, and HTTPS access to the public VM from any IP address.
- Internal communication between VMs is allowed on all ports.
- The Google Cloud credentials:
  - For local development: Use `gcloud auth application-default login` to create credentials.
  - For CI/CD: Credentials are provided through the `GCP_SA_KEY` secret and the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.
