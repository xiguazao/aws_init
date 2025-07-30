#!/bin/bash

# AWS EC2 Instance Management Functions
# Source this file to use its functions

# Function to validate required parameters
validate_ec2_params() {
    if [[ -z "$EC2_REGION" || -z "$EC2_INSTANCE_TYPE" || -z "$EC2_AMI_ID" || -z "$EC2_KEY_PAIR_NAME" ]]; then
        echo "Error: Missing required EC2 parameters"
        echo "Required: EC2_REGION, EC2_INSTANCE_TYPE, EC2_AMI_ID, EC2_KEY_PAIR_NAME"
        exit 1
    fi

    if [[ -n "$EC2_IAM_PROFILE" ]]; then
        export AWS_PROFILE="$EC2_IAM_PROFILE"
    fi
}

# Function to find subnet based on project and type (public/private)
find_subnet() {
    local project_name=$1
    local subnet_type=$2  # public or private
    local az_num=$3       # availability zone number
    
    local subnet_name="${project_name}-${subnet_type}-subnet-az${az_num}"
    
    echo "Finding subnet: $subnet_name"
    
    local subnet_id=$(aws ec2 describe-subnets \
        --region $EC2_REGION \
        --filters "Name=tag:Name,Values=$subnet_name" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
        
    if [[ "$subnet_id" == "None" || -z "$subnet_id" ]]; then
        echo "Error: Subnet $subnet_name not found"
        return 1
    fi
    
    echo "$subnet_id"
}

# Function to create EC2 instance
create_ec2_instance() {
    local instance_name=$1
    local project_name=$2
    
    echo "Creating EC2 instance: $instance_name"
    
    # Find VPC
    local vpc_name="${project_name}-vpc"
    local vpc_id=$(aws ec2 describe-vpcs \
        --region $EC2_REGION \
        --filters "Name=tag:Name,Values=$vpc_name" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [[ "$vpc_id" == "None" || -z "$vpc_id" ]]; then
        echo "Error: VPC $vpc_name not found"
        return 1
    fi
    
    echo "Found VPC: $vpc_id"
    
    # Find subnet
    local subnet_id=$(find_subnet "$project_name" "$EC2_SUBNET_TYPE" "$EC2_AVAILABILITY_ZONE_NUM")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "Using subnet: $subnet_id"
    
    # Prepare security groups
    local sg_params=""
    if [[ -n "$EC2_SECURITY_GROUPS" ]]; then
        # Convert comma-separated list to array
        IFS=',' read -ra SG_NAMES <<< "$EC2_SECURITY_GROUPS"
        for sg_name in "${SG_NAMES[@]}"; do
            # Find security group by name
            local sg_id=$(aws ec2 describe-security-groups \
                --region $EC2_REGION \
                --filters "Name=group-name,Values=$sg_name" "Name=vpc-id,Values=$vpc_id" \
                --query 'SecurityGroups[0].GroupId' \
                --output text 2>/dev/null)
            
            if [[ "$sg_id" != "None" && -n "$sg_id" ]]; then
                sg_params="$sg_params --security-group-ids $sg_id"
            else
                echo "Warning: Security group $sg_name not found"
            fi
        done
    else
        # Use default security group if none specified
        local default_sg=$(aws ec2 describe-security-groups \
            --region $EC2_REGION \
            --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=default" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        sg_params="--security-group-ids $default_sg"
    fi
    
    # Create the instance
    echo "Launching instance with parameters:"
    echo "  AMI: $EC2_AMI_ID"
    echo "  Instance Type: $EC2_INSTANCE_TYPE"
    echo "  Key Pair: $EC2_KEY_PAIR_NAME"
    echo "  Subnet: $subnet_id"
    echo "  Security Groups: $sg_params"
    
    local instance_id=$(aws ec2 run-instances \
        --image-id $EC2_AMI_ID \
        --instance-type $EC2_INSTANCE_TYPE \
        --key-name $EC2_KEY_PAIR_NAME \
        --subnet-id $subnet_id \
        $sg_params \
        --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":$EC2_VOLUME_SIZE,\"VolumeType\":\"gp2\"}}]" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
        --region $EC2_REGION \
        --query 'Instances[0].InstanceId' \
        --output text 2>/dev/null)
    
    if [[ "$instance_id" == "None" || -z "$instance_id" ]]; then
        echo "Error: Failed to create EC2 instance"
        return 1
    fi
    
    echo "EC2 instance created successfully: $instance_id"
    
    # Wait for instance to be running
    echo "Waiting for instance to start..."
    aws ec2 wait instance-running --instance-ids $instance_id --region $EC2_REGION
    
    # Get instance details
    local public_ip=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --region $EC2_REGION \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null)
        
    local private_ip=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --region $EC2_REGION \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text 2>/dev/null)
    
    echo "Instance is running:"
    echo "  Instance ID: $instance_id"
    echo "  Public IP: $public_ip"
    echo "  Private IP: $private_ip"
    
    # Save instance info to a file
    cat > "${instance_name}_info.txt" << EOF
Instance ID: $instance_id
Public IP: $public_ip
Private IP: $private_ip
SSH Command: ssh -i $EC2_SSH_KEY_PATH $EC2_SSH_USER@$public_ip
EOF
    
    echo "Instance information saved to ${instance_name}_info.txt"
}

# Function to list EC2 instances
list_ec2_instances() {
    local project_name=$1
    
    echo "Listing EC2 instances for project: $project_name"
    
    aws ec2 describe-instances \
        --region $EC2_REGION \
        --filters "Name=tag:Name,Values=${project_name}*" \
        --query 'Reservations[].Instances[].[InstanceId, InstanceType, State.Name, PublicIpAddress, PrivateIpAddress, Tags[?Key==`Name`].Value|[0]]' \
        --output table
}

# Function to terminate EC2 instance
terminate_ec2_instance() {
    local instance_id=$1
    
    echo "Terminating EC2 instance: $instance_id"
    
    aws ec2 terminate-instances \
        --instance-ids $instance_id \
        --region $EC2_REGION \
        --output table
    
    echo "Waiting for instance to terminate..."
    aws ec2 wait instance-terminated --instance-ids $instance_id --region $EC2_REGION
    
    echo "Instance terminated successfully"
}

# Main function to initialize EC2 infrastructure
init_ec2_infrastructure() {
    source ../config/aws_config.sh
    load_aws_config
    
    # Load EC2 specific configuration
    source ./ec2_config.sh
    load_ec2_config
    
    # Validate parameters
    validate_ec2_params
    
    # Create EC2 instance
    create_ec2_instance "$EC2_INSTANCE_NAME" "$PROJECT_NAME"
    
    echo "EC2 infrastructure initialization completed for project: $PROJECT_NAME"
}