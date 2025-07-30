#!/bin/bash

# AWS Security Group Manager
# Usage: ./sg_manager.sh --region us-east-1  --vpc_id "" 

security_list='[
    {"name": "proxy-web", "rules": [{"protocol": "TCP", "port": 5601, "source": "10.3.0.0/16"}]},
    {"name": "redis", "rules": [{"protocol": "TCP", "port": 6379, "source": "10.3.0.0/16"}]}
]'

echo "gw list :" $security_list
# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region) region="$2"; shift ;;
        --vpc_id) vpc_id="$2"; shift ;;
        --profile) iam_profile="$2"; shift ;;
        --project) project_name="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$region" || -z "$vpc_id" || -z "$project_name" ]]; then
    echo "Error: --region, --vpc_id and --project parameters are required"
    exit 1
fi

# Set AWS profile if specified
if [[ -n "$iam_profile" ]]; then
    export AWS_PROFILE="$iam_profile"
fi

# Get default VPC if not specified
if [[ -z "$vpc_id" ]]; then
    vpc_id=$(aws ec2 describe-vpcs --region "$region" --query 'Vpcs[?IsDefault==`true`].VpcId' --output text)
    echo "Using default VPC: $vpc_id"
fi

# 遍历 JSON 列表中的每个字典
echo "$security_list" | jq -c '.[]' | while read -r gw_info; do
    # # Parse JSON config
    group_name=$project_name-$(echo "$gw_info" | jq -r '.name')

    rules=$(echo "$gw_info" | jq -r '.rules')

    echo "Creating security group: $group_name, vpc_id:$vpc_id, region:$region"
    group_id=$(aws ec2 create-security-group \
        --group-name "$group_name" \
        --description "Security group for $group_name" \
        --vpc-id "$vpc_id" \
        --region "$region" \
        --query 'GroupId' \
        --output text)

    echo "Security group created: $group_id"

    # # Add rules
    # echo "$rules" | jq -c '.[]' | while read -r rule; do
    #     protocol=$(echo "$rule" | jq -r '.protocol')
    #     from_port=$(echo "$rule" | jq -r '.port')
    #     to_port=$(echo "$rule" | jq -r '.port')
    #     cidr=$(echo "$rule" | jq -r '.source')

    #     echo "Adding rule: $protocol $from_port-$to_port from $cidr"
        
    #     aws ec2 authorize-security-group-ingress \
    #         --group-id "$group_id" \
    #         --protocol "$protocol" \
    #         --port "$from_port" \
    #         --cidr "$cidr" \
    #         --region "$region"
    # done

    # echo "Security group configuration completed:"
    # aws ec2 describe-security-groups --group-ids "$group_id" --region "$region" --query 'SecurityGroups[0]'
done