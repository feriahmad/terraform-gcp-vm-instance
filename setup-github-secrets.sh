#!/bin/bash

# Script to help set up GitHub secrets for Atlantis CI/CD workflow
# This script guides you through creating a GCP service account and setting up GitHub secrets

echo "Setting up GitHub secrets for Atlantis CI/CD workflow"
echo "===================================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed. Please install it first."
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Warning: GitHub CLI is not installed. You'll need to set up secrets manually."
    echo "Visit: https://cli.github.com/ to install GitHub CLI"
    MANUAL_SETUP=true
else
    MANUAL_SETUP=false
fi

# Get GitHub repository information
echo "Enter your GitHub username:"
read GITHUB_USERNAME

echo "Enter your repository name (default: terraform-gcp-vm-instance):"
read REPO_NAME
REPO_NAME=${REPO_NAME:-terraform-gcp-vm-instance}

# Create GCP service account
echo ""
echo "Creating GCP service account for Terraform..."
echo "This service account will be used by Terraform to create resources in GCP."
echo ""

echo "Enter a name for the service account (default: terraform-atlantis):"
read SA_NAME
SA_NAME=${SA_NAME:-terraform-atlantis}

echo "Enter your GCP project ID (default: polished-tube-312806):"
read PROJECT_ID
PROJECT_ID=${PROJECT_ID:-polished-tube-312806}

# Create service account
echo "Creating service account $SA_NAME in project $PROJECT_ID..."
gcloud iam service-accounts create $SA_NAME \
    --display-name="Terraform Atlantis Service Account" \
    --project=$PROJECT_ID

# Grant necessary roles to the service account
echo "Granting necessary roles to the service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download service account key
echo "Creating and downloading service account key..."
gcloud iam service-accounts keys create gcp-sa-key.json \
    --iam-account=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com

# Set up GitHub secrets
if [ "$MANUAL_SETUP" = false ]; then
    echo "Setting up GitHub secrets using GitHub CLI..."
    
    # Check if user is logged in to GitHub CLI
    if ! gh auth status &> /dev/null; then
        echo "You need to log in to GitHub CLI first."
        gh auth login
    fi
    
    # Set GCP_SA_KEY secret
    echo "Setting GCP_SA_KEY secret in GitHub repository..."
    gh secret set GCP_SA_KEY -b"$(cat gcp-sa-key.json)" -R $GITHUB_USERNAME/$REPO_NAME
    
    echo "GitHub secrets set up successfully!"
else
    echo ""
    echo "Manual GitHub Secret Setup Instructions:"
    echo "========================================"
    echo "1. Go to your GitHub repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "2. Navigate to Settings > Secrets and variables > Actions"
    echo "3. Click on 'New repository secret'"
    echo "4. Add the following secret:"
    echo "   Name: GCP_SA_KEY"
    echo "   Value: (Copy the contents of the gcp-sa-key.json file)"
    echo ""
fi

echo "Setup complete!"
echo "IMPORTANT: For security, delete the gcp-sa-key.json file after you've set up the GitHub secret."
echo "You can delete it with: rm gcp-sa-key.json"
echo ""
echo "Note: The gcp-sa-key.json file is already added to .gitignore to prevent accidental commits,"
echo "but it's still recommended to delete it after setting up the GitHub secret."
echo ""
echo "Additional Secrets Setup:"
echo "------------------------"

echo "1. SSH Key Information:"
echo "   For CI/CD environments, a dummy SSH key is automatically set in the GitHub Actions workflow."
echo "   In production, you should set a real SSH key using GitHub Secrets."
echo ""
echo "   To add your SSH public key as a GitHub secret:"
echo "   a. Generate an SSH key pair if you don't already have one:"
echo "      ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
echo ""
echo "   b. Add the public key as a GitHub secret named SSH_PUBLIC_KEY:"
if [ "$MANUAL_SETUP" = false ]; then
    echo "      You can use the GitHub CLI to add it:"
    echo "      gh secret set SSH_PUBLIC_KEY -b\"$(cat ~/.ssh/id_rsa.pub)\" -R $GITHUB_USERNAME/$REPO_NAME"
else
    echo "      i. Go to your GitHub repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "      ii. Navigate to Settings > Secrets and variables > Actions"
    echo "      iii. Click on 'New repository secret'"
    echo "      iv. Name: SSH_PUBLIC_KEY"
    echo "      v. Value: (Copy the contents of your ~/.ssh/id_rsa.pub file)"
fi
echo ""

echo "2. Infracost API Key:"
echo "   To enable cost estimation for your Terraform changes, you need to set up an Infracost API key."
echo ""
echo "   a. Sign up for a free Infracost account at https://www.infracost.io"
echo "   b. Get your API key from the Infracost dashboard"
echo "   c. Add the API key as a GitHub secret named INFRACOST_API_KEY:"
if [ "$MANUAL_SETUP" = false ]; then
    echo "      You can use the GitHub CLI to add it:"
    echo "      gh secret set INFRACOST_API_KEY -b\"your-api-key\" -R $GITHUB_USERNAME/$REPO_NAME"
else
    echo "      i. Go to your GitHub repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo "      ii. Navigate to Settings > Secrets and variables > Actions"
    echo "      iii. Click on 'New repository secret'"
    echo "      iv. Name: INFRACOST_API_KEY"
    echo "      v. Value: (Paste your Infracost API key)"
fi
echo ""
echo "The GitHub Actions workflow is already configured to use these secrets if they exist."
