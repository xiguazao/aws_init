#!/bin/bash

# EC2 Instance Configuration
load_ec2_config() {
    # Default EC2 parameters
    export EC2_REGION=${EC2_REGION:-"ap-east-1"}
    export EC2_INSTANCE_TYPE=${EC2_INSTANCE_TYPE:-"t3.micro"}
    export EC2_AMI_ID=${EC2_AMI_ID:-"ami-096000e0f057a17ea"}  # Amazon Linux 2 AMI (ap-east-1)
    export EC2_KEY_PAIR_NAME=${EC2_KEY_PAIR_NAME:-"my-key-pair"}
    export EC2_PROJECT_NAME=${EC2_PROJECT_NAME:-"HMBS"}
    
    # Network configuration
    export EC2_SUBNET_TYPE=${EC2_SUBNET_TYPE:-"public"}  # public or private
    export EC2_AVAILABILITY_ZONE_NUM=${EC2_AVAILABILITY_ZONE_NUM:-"1"}  # 1st AZ by default
    
    # Security configuration
    export EC2_SECURITY_GROUPS=${EC2_SECURITY_GROUPS:-""}  # Comma-separated list
    
    # Instance configuration
    export EC2_INSTANCE_NAME=${EC2_INSTANCE_NAME:-"${EC2_PROJECT_NAME}-ec2-instance"}
    export EC2_VOLUME_SIZE=${EC2_VOLUME_SIZE:-"10"}  # GB
    
    # SSH configuration
    export EC2_SSH_USER=${EC2_SSH_USER:-"ec2-user"}
    export EC2_SSH_KEY_PATH=${EC2_SSH_KEY_PATH:-"~/.ssh/${EC2_KEY_PAIR_NAME}.pem"}
}