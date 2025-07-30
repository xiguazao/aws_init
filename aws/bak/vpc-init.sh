#!/bin/bash

# AWS Network Initialization Script with Project Naming
# Usage: ./vpc.sh --region <region> --azs <availability_zones> --profile <iam_profile> --project <project_name>

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region) region="$2"; shift ;;
        --azs) availability_zones="$2"; shift ;;
        --profile) iam_profile="$2"; shift ;;
        --project) project_name="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$region" || -z "$availability_zones" || -z "$project_name" ]]; then
    echo "Error: --region, --azs and --project parameters are required"
    exit 1
fi

# Set AWS profile if specified
if [[ -n "$iam_profile" ]]; then
    export AWS_PROFILE="$iam_profile"
fi

# Define naming patterns
VPC_NAME="${project_name}-vpc"
IGW_NAME="${project_name}-igw"
PUBLIC_SUBNET_PATTERN="${project_name}-public-subnet-az"
PRIVATE_SUBNET_PATTERN="${project_name}-private-subnet-az"
PUBLIC_RT_NAME="${project_name}-public-rt"
PRIVATE_RT_PATTERN="${project_name}-private-rt-az"
NAT_GW_PATTERN="${project_name}-natgw-az"


# VPC CIDR
VPC_CIDR="10.3.0.0/16"

# Define subnet CIDR blocks
declare -A SUBNET_CIDRS=(
    ["public"]="10.3.{AZ_NUM}.0/24"
    ["private"]="10.3.{AZ_NUM}.0/24"
)

gw_list='[
    {"name": "proxy-web", "rules": [{"protocol": "TCP", "port": 5601, "source": "10.3.0.0/16"}]},
    {"name": "redis", "rules": [{"protocol": "TCP", "port": 6379, "source": "10.3.0.0/16"}]}
]'


# Create VPC with name tag
echo "Creating VPC: $VPC_NAME..."
vpc_id=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $region --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value="$VPC_NAME" --region $region
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}" --region $region
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" --region $region
echo "Created VPC: $VPC_NAME ($vpc_id)"

# Create Internet Gateway with name tag
echo "Creating Internet Gateway: $IGW_NAME..."
igw_id=$(aws ec2 create-internet-gateway --region $region --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value="$IGW_NAME" --region $region
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region
echo "Created Internet Gateway: $IGW_NAME ($igw_id)"


# Create Route Table for Public Subnet with name tag
public_rt_name="${PUBLIC_RT_NAME}"
echo "Configuring Route Table: $public_rt_name..."
public_rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $public_rt_id --tags Key=Name,Value="$public_rt_name" --region $region
# aws ec2 associate-route-table --route-table-id $public_rt_id --subnet-id $public_subnet_id --region $region
aws ec2 create-route --route-table-id $public_rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region
echo "Configured Public Route Table: $public_rt_name ($public_rt_id)"

# Process each availability zone
az_num=1
for az in $(echo $availability_zones | tr ',' ' '); do
    echo "Processing Availability Zone: $az"
    
    # Create Public Subnet with name tag
    public_cidr=$(echo ${SUBNET_CIDRS["public"]} | sed "s/{AZ_NUM}/$((az_num * 10))/g")
    public_subnet_name="${PUBLIC_SUBNET_PATTERN}${az_num}"
    echo "Creating Public Subnet ($public_subnet_name)..."
    public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $public_cidr --availability-zone $az --region $region --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $public_subnet_id --tags Key=Name,Value="$public_subnet_name" --region $region
    echo "Created Public Subnet: $public_subnet_name ($public_subnet_id)"
    
    aws ec2 associate-route-table --route-table-id $public_rt_id --subnet-id $public_subnet_id --region $region
    echo "Configured Public Route Table: $public_rt_name ($public_rt_id)"

    # Create Private Subnet with name tag
    private_cidr=$(echo ${SUBNET_CIDRS["private"]} | sed "s/{AZ_NUM}/$((az_num * 10 + 1))/g")
    private_subnet_name="${PRIVATE_SUBNET_PATTERN}${az_num}"
    echo "Creating Private Subnet ($private_subnet_name)..."
    private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $private_cidr --availability-zone $az --region $region --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $private_subnet_id --tags Key=Name,Value="$private_subnet_name" --region $region
    echo "Created Private Subnet: $private_subnet_name ($private_subnet_id)"
    
    # Allocate Elastic IP for NAT Gateway
    echo "Allocating Elastic IP for NAT Gateway..."
    allocation_id=$(aws ec2 allocate-address --domain vpc --region $region --query 'AllocationId' --output text)
    echo "Allocated EIP: $allocation_id"
    
    # Create NAT Gateway with name tag
    nat_gw_name="${NAT_GW_PATTERN}${az_num}"
    echo "Creating NAT Gateway: $nat_gw_name..."
    nat_gw_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $allocation_id --region $region --query 'NatGateway.NatGatewayId' --output text)
    aws ec2 create-tags --resources $nat_gw_id --tags Key=Name,Value="$nat_gw_name" --region $region
    echo "Created NAT Gateway: $nat_gw_name ($nat_gw_id)"
    
    # Create Route Table for Private Subnet with name tag
    private_rt_name="${PRIVATE_RT_PATTERN}${az_num}"
    echo "Configuring Route Table: $private_rt_name..."
    private_rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-tags --resources $private_rt_id --tags Key=Name,Value="$private_rt_name" --region $region
    aws ec2 associate-route-table --route-table-id $private_rt_id --subnet-id $private_subnet_id --region $region
    
    aws ec2 create-route --route-table-id $private_rt_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gw_id --region $region
    echo "Configured Private Route Table: $private_rt_name ($private_rt_id)"
    
    ((az_num++))
done

echo "Network initialization completed successfully for project: $project_name"