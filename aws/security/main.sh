#!/bin/bash

# Main Security Group Management Script
# Usage: ./main.sh --project <project_name> --region <region> --vpc-id <vpc_id> [other options]

# Source the function libraries
source ../config/aws_config.sh
source ./security_manage.sh

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT_NAME="$2"; shift ;;
        --region) REGION="$2"; shift ;;
        --vpc-id) VPC_ID="$2"; shift ;;
        --profile) IAM_PROFILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

main() {
    echo "Starting security group management..."
    
    # Load configurations
    load_aws_config
    
    # Override with command line parameters if provided
    export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
    export REGION=${REGION:-$REGION}
    export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
    
    # Manage security groups
    echo "1. Managing security groups..."
    manage_security_groups "$VPC_ID"
    echo "Security group management completed"
    
    echo "Security group setup completed for project: $PROJECT_NAME"
}

main "$@"