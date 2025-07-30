#!/bin/bash

# AWS VPC Cleanup Script
# Usage: ./vpc_cleanup.sh --vpc-id <vpc_id> --region <region> [--profile <iam_profile>]

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --vpc_id) vpc_id="$2"; shift ;;
        --region) region="$2"; shift ;;
        --profile) iam_profile="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$vpc_id" || -z "$region" ]]; then
    echo "Error: --vpc-id and --region parameters are required"
    exit 1
fi

# Set AWS profile if specified
if [[ -n "$iam_profile" ]]; then
    export AWS_PROFILE="$iam_profile"
fi

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local resource_id=$2
    local max_retries=30
    local retry=0
    
    echo "Waiting for $resource_type ($resource_id) to be deleted..."
    while [[ $retry -lt $max_retries ]]; do
        if aws ec2 describe-$resource_type --$resource_type-ids $resource_id --region $region 2>&1 | grep -q "Invalid"; then
            return 0
        fi
        sleep 10
        ((retry++))
    done
    echo "Timeout waiting for $resource_type deletion"
    return 1
}

echo "Starting cleanup for VPC: $vpc_id in region: $region"

# 1. Delete NAT Gateways
echo "Finding NAT Gateways..."
nat_gws=$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$vpc_id Name=state,Values=available --region $region --query 'NatGateways[*].NatGatewayId' --output text)
for nat_gw in $nat_gws; do
    echo "Deleting NAT Gateway: $nat_gw"
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_gw --region $region
    wait_for_deletion "nat-gateways" $nat_gw
done

# 2. Release Elastic IPs
echo "Finding Elastic IPs..."
eips=$(aws ec2 describe-addresses --filter Name=domain,Values=vpc --region $region --query 'Addresses[?AssociationId==null].AllocationId' --output text)
for eip in $eips; do
    echo "Releasing Elastic IP: $eip"
    aws ec2 release-address --allocation-id $eip --region $region
done

# 3. Detach and Delete Internet Gateways
echo "Finding Internet Gateways..."
igws=$(aws ec2 describe-internet-gateways --filter Name=attachment.vpc-id,Values=$vpc_id --region $region --query 'InternetGateways[*].InternetGatewayId' --output text)
for igw in $igws; do
    echo "Detaching Internet Gateway: $igw"
    aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc_id --region $region
    echo "Deleting Internet Gateway: $igw"
    aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $region
done

# 4. Delete Subnets
echo "Finding Subnets..."
subnets=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$vpc_id --region $region --query 'Subnets[*].SubnetId' --output text)
for subnet in $subnets; do
    echo "Deleting Subnet: $subnet"
    aws ec2 delete-subnet --subnet-id $subnet --region $region
done

# 5. Delete Route Tables (except main)
echo "Finding Route Tables..."
rtables=$(aws ec2 describe-route-tables --filter Name=vpc-id,Values=$vpc_id --region $region --query 'RouteTables[?Associations==null || length(Associations)==`0`].RouteTableId' --output text)
for rtable in $rtables; do
    echo "Deleting Route Table: $rtable"
    aws ec2 delete-route-table --route-table-id $rtable --region $region
done

# 6. Delete Security Groups (except default)
echo "Finding Security Groups..."
sgs=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$vpc_id --region $region --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
for sg in $sgs; do
    echo "Deleting Security Group: $sg"
    aws ec2 delete-security-group --group-id $sg --region $region
done

# 7. Delete VPC
echo "Deleting VPC: $vpc_id"
aws ec2 delete-vpc --vpc-id $vpc_id --region $region

echo "Cleanup completed for VPC: $vpc_id"