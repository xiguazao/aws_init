#!/bin/bash

# AWS Security Group Manager (function library)
# Source this file to use its functions

# Global variables
declare -A SG_CACHE  # Cache for security group IDs

create_security_group() {
    local group_name=$1
    local VPC_ID=$2
    local REGION=$3
    local description="${4:-Security group for $group_name}"

    echo "Creating security group: $group_name"
    local group_id=$(aws ec2 create-security-group \
        --group-name "$group_name" \
        --description "$description" \
        --vpc-id "$VPC_ID" \
        --region "$REGION" \
        --query 'GroupId' \
        --output text)
    
    SG_CACHE["$group_name"]=$group_id
    echo "Created security group: $group_id"
    echo "$group_id"
}

add_security_group_rules() {
    local group_id=$1
    local rules_json=$2
    local region=$3

    echo "$rules_json" | jq -c '.[]' | while read -r rule; do
        local protocol=$(echo "$rule" | jq -r '.protocol')
        local from_port=$(echo "$rule" | jq -r '.port')
        local to_port=$(echo "$rule" | jq -r '.port')
        local cidr=$(echo "$rule" | jq -r '.source')

        echo "Adding rule: $protocol $from_port-$to_port from $cidr"
        
        aws ec2 authorize-security-group-ingress \
            --group-id "$group_id" \
            --protocol "$protocol" \
            --port "$from_port" \
            --cidr "$cidr" \
            --region "$region"
    done
}

validate_security_params() {
    if [[ -z "$REGION" || -z "$Security_LIST" || -z "$PROJECT_NAME" ]]; then
        echo "Error: --region, --Security_LIST and --project parameters are required"
        exit 1
    fi

    if [[ -n "$IAM_PROFILE" ]]; then
        export AWS_PROFILE="$IAM_PROFILE"
    fi
}

manage_security_groups() {
    source ../config/aws_config.sh
    load_aws_config

    local VPC_ID=$1
    
    validate_security_params
    
    if [[ -z "$VPC_ID" ]]; then
        echo "Error: VPC ID is required"
        exit 1
    fi

    echo "$Security_LIST" | jq -c '.[]' | while read -r gw_info; do
        local name=$(echo "$gw_info" | jq -r '.name')
        local rules=$(echo "$gw_info" | jq -r '.rules')
        local group_name="${PROJECT_NAME}-${name}"

        local group_id=$(create_security_group "$group_name" "$VPC_ID" "$REGION")
        add_security_group_rules "$group_id" "$rules" "$REGION"
        
        echo "Security group configuration completed:"
        aws ec2 describe-security-groups --group-ids "$group_id" --region "$REGION" --query 'SecurityGroups[0]'
    done
}

#  manage_security_groups "$security_list" "$VPC_ID" "$REGION" "$PROJECT_NAME"