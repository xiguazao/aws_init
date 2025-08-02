# Terraform Backend Configuration
# This is a template for remote state storage configuration
# Uncomment and customize the sections you need for remote state management

# S3 Backend Configuration (Recommended for AWS environments)
# terraform {
#  backend "s3" {
#    bucket         = "public-xigua"     # Replace with your S3 bucket name
#    key            = "public-xigua/terraform.tfstate"  # Path within the bucket
#    region         = "ap-southeast-1"                     # Region where the bucket is located
#    encrypt        = false                            # Enable encryption of the state file
#    # dynamodb_table = "terraform-state-lock"          # DynamoDB table for state locking
#    # role_arn     = "arn:aws:iam::123456789012:role/TerraformStateManagement"  # Optional: IAM role to assume
#  }
#}

# Alternative Backends (Uncomment the one you want to use)

# Azure Blob Storage Backend
# terraform {
#   backend "azurerm" {
#     storage_account_name = "myterraformstate"
#     container_name       = "terraform-state"
#     key                  = "aws-infrastructure/terraform.tfstate"
#   }
# }

# Google Cloud Storage Backend
# terraform {
#   backend "gcs" {
#     bucket = "my-terraform-state-bucket"
#     prefix = "aws-infrastructure"
#   }
# }

# Local Backend (Default - stores state locally)
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# When changing backends, run:
# terraform init -reconfigure

# For more information about backends, see:
# https://www.terraform.io/docs/language/settings/backends/index.html