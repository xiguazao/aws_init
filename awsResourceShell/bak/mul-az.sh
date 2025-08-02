#!/bin/bash

# AWS Network Initialization Script with AZ/Subnet Dictionary
# Usage: ./aws_network_init.sh --region <region> --azs <availability_zones> --profile <iam_profile>

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region) region="$2"; shift ;;
        --azs) availability_zones="$2"; shift ;;
        --profile) iam_profile="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$region" || -z "$availability_zones" ]]; then
    echo "Error: --region and --azs parameters are required"
    exit 1
fi

# Set AWS profile if specified
if [[ -n "$iam_profile" ]]; then
    export AWS_PROFILE="$iam_profile"
fi

# Define subnet CIDR blocks (can be extended for more subnets per AZ)
declare -A SUBNET_CIDRS=(
    ["public"]="10.2.{AZ_NUM}.0/24"
    ["private"]="10.2.{AZ_NUM}.0/24"
)

# Create VPC
echo "Creating VPC in region $region..."
vpc_id=$(aws ec2 create-vpc --cidr-block 10.2.0.0/16 --region $region --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}" --region $region
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" --region $region
echo "Created VPC: $vpc_id"

# Create Internet Gateway
echo "Creating Internet Gateway..."
igw_id=$(aws ec2 create-internet-gateway --region $region --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region
echo "Created Internet Gateway: $igw_id"

# Process each availability zone
az_num=1
for az in $(echo $availability_zones | tr ',' ' '); do
    echo "Processing Availability Zone: $az"
    
    # Create Public Subnet
    public_cidr=$(echo ${SUBNET_CIDRS["public"]} | sed "s/{AZ_NUM}/$((az_num * 10))/g")
    echo "Creating Public Subnet ($public_cidr) in AZ $az..."
    public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $public_cidr --availability-zone $az --region $region --query 'Subnet.SubnetId' --output text)
    echo "Created Public Subnet: $public_subnet_id"
    
    # Create Private Subnet
    private_cidr=$(echo ${SUBNET_CIDRS["private"]} | sed "s/{AZ_NUM}/$((az_num * 10 + 1))/g")
    echo "Creating Private Subnet ($private_cidr) in AZ $az..."
    private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $private_cidr --availability-zone $az --region $region --query 'Subnet.SubnetId' --output text)
    echo "Created Private Subnet: $private_subnet_id"
    
    # Create Route Table for Public Subnet
    echo "Configuring Route Table for Public Subnet..."
    public_rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query 'RouteTable.RouteTableId' --output text)
    aws ec2 associate-route-table --route-table-id $public_rt_id --subnet-id $public_subnet_id --region $region
    aws ec2 create-route --route-table-id $public_rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region
    echo "Configured Public Route Table: $public_rt_id"
    
    # Allocate Elastic IP for NAT Gateway (one per AZ)
    echo "Allocating Elastic IP for NAT Gateway..."
    allocation_id=$(aws ec2 allocate-address --domain vpc --region $region --query 'AllocationId' --output text)
    echo "Allocated EIP: $allocation_id"
    
    # Create NAT Gateway in Public Subnet
    echo "Creating NAT Gateway in Public Subnet..."
    nat_gw_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $allocation_id --region $region --query 'NatGateway.NatGatewayId' --output text)
    echo "Created NAT Gateway: $nat_gw_id"
    
    # Create Route Table for Private Subnet
    echo "Configuring Route Table for Private Subnet..."
    private_rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query 'RouteTable.RouteTableId' --output text)
    aws ec2 associate-route-table --route-table-id $private_rt_id --subnet-id $private_subnet_id --region $region
    aws ec2 create-route --route-table-id $private_rt_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gw_id --region $region
    echo "Configured Private Route Table: $private_rt_id"
    
    ((az_num++))
done

echo "Network initialization completed successfully for AZs: $availability_zones"