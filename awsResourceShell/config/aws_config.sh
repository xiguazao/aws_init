#!/bin/bash

# AWS Infrastructure Configuration
load_aws_config() {

    # Default parameters
    export REGION=${REGION:-"ap-east-1"}
    export AVAILABILITY_ZONES=${AVAILABILITY_ZONES:-"ap-east-1a,ap-east-1b"}
    export IAM_PROFILE=${IAM_PROFILE:-""}
    export PROJECT_NAME=${PROJECT_NAME:-"HMBS"}

    # Network CIDR Configuration
    export VPC_CIDR="10.3.0.0/16"
    
    # Network Subnet Configuration
    declare -Ag SUBNET_CIDRS=(
        ["public"]="10.3.{AZ_NUM}.0/24"
        ["private"]="10.3.{AZ_NUM}.0/24"
    )

    # Security Group Configuration
    export Security_LIST='[
        {"name": "proxy-web", "rules": [{"protocol": "TCP","port": 5601,"source": "10.3.0.0/16"}]},
        {"name": "redis", "rules": [{"protocol": "TCP","port": 6379,"source": "10.3.0.0/16"}]},
        {"name": "WireVpn", "rules": [{"protocol": "TCP","port": "10034-10040","source": "10.3.0.0/16"}]}
    ]'
}