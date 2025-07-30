#!/bin/bash

# Subnet Configuration Storage
# This file stores subnet IDs for use by other components

# Initialize subnet configuration
init_subnet_config() {
    # Create an associative array to store subnet IDs
    declare -gA SUBNET_IDS
}

# Save subnet ID to configuration
save_subnet_id() {
    local subnet_type=$1    # public or private
    local az_num=$2         # availability zone number
    local subnet_id=$3      # subnet ID
    
    SUBNET_IDS["${subnet_type}_az${az_num}"]="$subnet_id"
    echo "Saved ${subnet_type} subnet ID for AZ${az_num}: $subnet_id"
}

# Get subnet ID from configuration
get_subnet_id() {
    local subnet_type=$1    # public or private
    local az_num=$2         # availability zone number
    
    echo "${SUBNET_IDS["${subnet_type}_az${az_num}"]}"
}

# Save NAT Gateway ID to configuration
save_nat_gateway_id() {
    local az_num=$1         # availability zone number
    local nat_gw_id=$2      # NAT gateway ID
    
    SUBNET_IDS["natgw_az${az_num}"]="$nat_gw_id"
    echo "Saved NAT Gateway ID for AZ${az_num}: $nat_gw_id"
}

# Get NAT Gateway ID from configuration
get_nat_gateway_id() {
    local az_num=$1         # availability zone number
    
    echo "${SUBNET_IDS["natgw_az${az_num}"]}"
}

# Save VPC ID to configuration
save_vpc_id() {
    local vpc_id=$1
    
    SUBNET_IDS["vpc_id"]="$vpc_id"
    echo "Saved VPC ID: $vpc_id"
}

# Get VPC ID from configuration
get_vpc_id() {
    echo "${SUBNET_IDS["vpc_id"]}"
}

# Save Internet Gateway ID to configuration
save_igw_id() {
    local igw_id=$1
    
    SUBNET_IDS["igw_id"]="$igw_id"
    echo "Saved Internet Gateway ID: $igw_id"
}

# Get Internet Gateway ID from configuration
get_igw_id() {
    echo "${SUBNET_IDS["igw_id"]}"
}

# Save Public Route Table ID to configuration
save_public_rt_id() {
    local rt_id=$1
    
    SUBNET_IDS["public_rt_id"]="$rt_id"
    echo "Saved Public Route Table ID: $rt_id"
}

# Get Public Route Table ID from configuration
get_public_rt_id() {
    echo "${SUBNET_IDS["public_rt_id"]}"
}

# Save Private Route Table ID to configuration
save_private_rt_id() {
    local az_num=$1
    local rt_id=$2
    
    SUBNET_IDS["private_rt_az${az_num}"]="$rt_id"
    echo "Saved Private Route Table ID for AZ${az_num}: $rt_id"
}

# Get Private Route Table ID from configuration
get_private_rt_id() {
    local az_num=$1
    
    echo "${SUBNET_IDS["private_rt_az${az_num}"]}"
}