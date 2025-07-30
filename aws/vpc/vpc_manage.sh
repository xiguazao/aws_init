#!/bin/bash

# AWS Network Infrastructure Functions
# Source this file to use its functions

source ../config/subnet_config.sh

create_vpc() {
    echo "Creating VPC: $VPC_NAME..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value="$VPC_NAME" --region $REGION
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}" --region $REGION
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}" --region $REGION
    echo "Created VPC: $VPC_NAME ($VPC_ID)"
    
    # Save VPC ID to configuration
    save_vpc_id "$VPC_ID"
}

create_subnets() {
    echo "Creating subnets..."
    
    # Process each availability zone
    az_num=1
    for az in $(echo $AVAILABILITY_ZONES | tr ',' ' '); do
        echo "Processing Availability Zone: $az"
        
        # Create Public Subnet
        public_cidr=$(echo ${SUBNET_CIDRS["public"]} | sed "s/{AZ_NUM}/$((az_num * 10))/g")
        public_subnet_name="${PUBLIC_SUBNET_PATTERN}${az_num}"
        echo "Creating Public Subnet ($public_subnet_name)..."
        public_subnet_id=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $public_cidr --availability-zone $az --region $REGION --query 'Subnet.SubnetId' --output text)
        aws ec2 create-tags --resources $public_subnet_id --tags Key=Name,Value="$public_subnet_name" --region $REGION
        echo "Created Public Subnet: $public_subnet_name ($public_subnet_id)"
        
        # Save public subnet ID to configuration
        save_subnet_id "public" "$az_num" "$public_subnet_id"
        
        # Create Private Subnet
        private_cidr=$(echo ${SUBNET_CIDRS["private"]} | sed "s/{AZ_NUM}/$((az_num * 10 + 1))/g")
        private_subnet_name="${PRIVATE_SUBNET_PATTERN}${az_num}"
        echo "Creating Private Subnet ($private_subnet_name)..."
        private_subnet_id=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $private_cidr --availability-zone $az --region $REGION --query 'Subnet.SubnetId' --output text)
        aws ec2 create-tags --resources $private_subnet_id --tags Key=Name,Value="$private_subnet_name" --region $REGION
        echo "Created Private Subnet: $private_subnet_name ($private_subnet_id)"
        
        # Save private subnet ID to configuration
        save_subnet_id "private" "$az_num" "$private_subnet_id"
        
        ((az_num++))
    done
}

create_igw() {
    echo "Creating Internet Gateway: $IGW_NAME..."
    igw_id=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 create-tags --resources $igw_id --tags Key=Name,Value="$IGW_NAME" --region $REGION
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $igw_id --region $REGION
    echo "Created Internet Gateway: $IGW_NAME ($igw_id)"
    
    # Save IGW ID to configuration
    save_igw_id "$igw_id"
}

create_nat_gateways() {
    echo "Creating NAT Gateways..."
    
    # Process each availability zone
    az_num=1
    for az in $(echo $AVAILABILITY_ZONES | tr ',' ' '); do
        echo "Processing Availability Zone: $az"
        
        # Get public subnet ID from configuration
        public_subnet_id=$(get_subnet_id "public" "$az_num")
        
        echo "Allocating Elastic IP for NAT Gateway..."
        allocation_id=$(aws ec2 allocate-address --domain vpc --region $REGION --query 'AllocationId' --output text)
        echo "Allocated EIP: $allocation_id"
        
        nat_gw_name="${NAT_GW_PATTERN}${az_num}"
        echo "Creating NAT Gateway: $nat_gw_name..."
        nat_gw_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $allocation_id --region $REGION --query 'NatGateway.NatGatewayId' --output text)
        aws ec2 create-tags --resources $nat_gw_id --tags Key=Name,Value="$nat_gw_name" --region $REGION
        echo "Created NAT Gateway: $nat_gw_name ($nat_gw_id)"
        
        # Save NAT Gateway ID to configuration
        save_nat_gateway_id "$az_num" "$nat_gw_id"
        
        ((az_num++))
    done
}

create_route_tables() {
    echo "Creating Route Tables..."
    
    # Create Public Route Table
    echo "Configuring Public Route Table: $PUBLIC_RT_NAME..."
    public_rt_id=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-tags --resources $public_rt_id --tags Key=Name,Value="$PUBLIC_RT_NAME" --region $REGION
    echo "Created Public Route Table: $PUBLIC_RT_NAME ($public_rt_id)"
    
    # Save Public Route Table ID to configuration
    save_public_rt_id "$public_rt_id"
    
    # Associate public subnets with public route table
    az_num=1
    for az in $(echo $AVAILABILITY_ZONES | tr ',' ' '); do
        public_subnet_id=$(get_subnet_id "public" "$az_num")
        echo "Associating Public Subnet $public_subnet_id with Public Route Table $public_rt_id"
        aws ec2 associate-route-table --route-table-id $public_rt_id --subnet-id $public_subnet_id --region $REGION
        
        ((az_num++))
    done
    
    # Create route to Internet Gateway in public route table
    igw_id=$(get_igw_id)
    echo "Creating route to Internet Gateway in Public Route Table..."
    aws ec2 create-route --route-table-id $public_rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $REGION
    
    # Create Private Route Tables
    az_num=1
    for az in $(echo $AVAILABILITY_ZONES | tr ',' ' '); do
        private_rt_name="${PRIVATE_RT_PATTERN}${az_num}"
        echo "Configuring Private Route Table: $private_rt_name..."
        private_rt_id=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
        aws ec2 create-tags --resources $private_rt_id --tags Key=Name,Value="$private_rt_name" --region $REGION
        echo "Created Private Route Table: $private_rt_name ($private_rt_id)"
        
        # Save Private Route Table ID to configuration
        save_private_rt_id "$az_num" "$private_rt_id"
        
        # Associate private subnet with private route table
        private_subnet_id=$(get_subnet_id "private" "$az_num")
        echo "Associating Private Subnet $private_subnet_id with Private Route Table $private_rt_id"
        aws ec2 associate-route-table --route-table-id $private_rt_id --subnet-id $private_subnet_id --region $REGION
        
        # Create route to NAT Gateway in private route table
        nat_gw_id=$(get_nat_gateway_id "$az_num")
        echo "Creating route to NAT Gateway in Private Route Table..."
        aws ec2 create-route --route-table-id $private_rt_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gw_id --region $REGION
        
        ((az_num++))
    done
}

validate_network_params() {
    if [[ -z "$REGION" || -z "$AVAILABILITY_ZONES" || -z "$PROJECT_NAME" ]]; then
        echo "Error: --region, --azs and --project parameters are required"
        exit 1
    fi

    if [[ -n "$IAM_PROFILE" ]]; then
        export AWS_PROFILE="$IAM_PROFILE"
    fi
}

init_vpc() {
    source ../config/aws_config.sh
    load_aws_config
    init_subnet_config

    # 参数校验
    validate_network_params
    
    # Define naming patterns
    VPC_NAME="${PROJECT_NAME}-vpc"
    IGW_NAME="${PROJECT_NAME}-igw"
    PUBLIC_SUBNET_PATTERN="${PROJECT_NAME}-public-subnet-az"
    PRIVATE_SUBNET_PATTERN="${PROJECT_NAME}-private-subnet-az"
    PUBLIC_RT_NAME="${PROJECT_NAME}-public-rt"
    PRIVATE_RT_PATTERN="${PROJECT_NAME}-private-rt-az"
    NAT_GW_PATTERN="${PROJECT_NAME}-natgw-az"

    create_vpc
    echo "VPC creation completed. VPC ID: $VPC_ID"
}

create_all_subnets() {
    source ../config/aws_config.sh
    load_aws_config
    init_subnet_config
    
    # Get VPC ID from configuration
    VPC_ID=$(get_vpc_id)
    
    if [[ -z "$VPC_ID" ]]; then
        echo "Error: VPC ID not found in configuration"
        exit 1
    fi
    
    # Define naming patterns
    PUBLIC_SUBNET_PATTERN="${PROJECT_NAME}-public-subnet-az"
    PRIVATE_SUBNET_PATTERN="${PROJECT_NAME}-private-subnet-az"
    
    create_subnets
    echo "Subnet creation completed"
}

create_all_gateways() {
    source ../config/aws_config.sh
    load_aws_config
    init_subnet_config
    
    # Get VPC ID from configuration
    VPC_ID=$(get_vpc_id)
    
    if [[ -z "$VPC_ID" ]]; then
        echo "Error: VPC ID not found in configuration"
        exit 1
    fi
    
    # Define naming patterns
    IGW_NAME="${PROJECT_NAME}-igw"
    NAT_GW_PATTERN="${PROJECT_NAME}-natgw-az"
    
    create_igw
    create_nat_gateways
    echo "Gateway creation completed"
}

create_all_route_tables() {
    source ../config/aws_config.sh
    load_aws_config
    init_subnet_config
    
    # Get VPC ID from configuration
    VPC_ID=$(get_vpc_id)
    
    if [[ -z "$VPC_ID" ]]; then
        echo "Error: VPC ID not found in configuration"
        exit 1
    fi
    
    # Define naming patterns
    PUBLIC_RT_NAME="${PROJECT_NAME}-public-rt"
    PRIVATE_RT_PATTERN="${PROJECT_NAME}-private-rt-az"
    
    create_route_tables
    echo "Route table creation completed"
}

init_network_infrastructure() {
    source ../config/aws_config.sh
    load_aws_config
    init_subnet_config

    # 参数校验
    validate_network_params
    
    # Define naming patterns
    VPC_NAME="${PROJECT_NAME}-vpc"
    IGW_NAME="${PROJECT_NAME}-igw"
    PUBLIC_SUBNET_PATTERN="${PROJECT_NAME}-public-subnet-az"
    PRIVATE_SUBNET_PATTERN="${PROJECT_NAME}-private-subnet-az"
    PUBLIC_RT_NAME="${PROJECT_NAME}-public-rt"
    PRIVATE_RT_PATTERN="${PROJECT_NAME}-private-rt-az"
    NAT_GW_PATTERN="${PROJECT_NAME}-natgw-az"

    create_vpc
    create_subnets
    create_igw
    create_nat_gateways
    create_route_tables

    echo "Network initialization completed successfully for project: $PROJECT_NAME"
    echo "VPC ID: $VPC_ID"
}