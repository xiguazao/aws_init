#!/bin/bash

# Main EC2 Creation Script
# Usage: ./main.sh --project <project_name> [other options]

# Source the function libraries
source ../config/aws_config.sh
source ./ec2_config.sh
source ./ec2_manage.sh

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT_NAME="$2"; EC2_PROJECT_NAME="$2"; shift ;;
        --region) EC2_REGION="$2"; REGION="$2"; shift ;;
        --instance-type) EC2_INSTANCE_TYPE="$2"; shift ;;
        --ami-id) EC2_AMI_ID="$2"; shift ;;
        --key-pair) EC2_KEY_PAIR_NAME="$2"; shift ;;
        --subnet-type) EC2_SUBNET_TYPE="$2"; shift ;;
        --az-num) EC2_AVAILABILITY_ZONE_NUM="$2"; shift ;;
        --instance-name) EC2_INSTANCE_NAME="$2"; shift ;;
        --security-groups) EC2_SECURITY_GROUPS="$2"; shift ;;
        --volume-size) EC2_VOLUME_SIZE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

main() {
    echo "Starting EC2 instance creation..."
    
    # Load configurations
    load_aws_config
    load_ec2_config
    
    # Override with command line parameters if provided
    export PROJECT_NAME=${PROJECT_NAME:-$EC2_PROJECT_NAME}
    export REGION=${REGION:-$EC2_REGION}
    
    # Initialize EC2 infrastructure
    echo "1. Initializing EC2 infrastructure..."
    init_ec2_infrastructure
    echo "EC2 infrastructure initialization completed"
    
    echo "EC2 setup completed for project: $PROJECT_NAME"
}

main "$@"