# AWS VPC Management

This directory contains scripts for managing VPC infrastructure in AWS with modular components that can be created separately.

## Directory Structure

```
vpc/
├── vpc_manage.sh         # Main VPC management functions
├── vpc_cleanup.sh        # VPC cleanup functions
├── main.sh               # Main script to create VPC infrastructure
└── README.md             # This file
```

## Usage

To create VPC infrastructure, you can either run the main initialization script from the root directory or use the VPC-specific script:

### Using the global script (from aws directory)
```bash
./main_init.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp
```

### Using the VPC-specific script (from vpc directory)
```bash
# Create all VPC components at once
cd vpc
./main.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp

# Create VPC only
./main.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp --action vpc

# Create subnets only (requires existing VPC)
./main.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp --action subnets

# Create gateways only (requires existing VPC and subnets)
./main.sh --region us-east-1 --project myapp --action gateways

# Create route tables only (requires existing VPC, subnets, and gateways)
./main.sh --region us-east-1 --project myapp --action routes
```

## Features

1. **Modular Creation**: Create VPC components separately (VPC, subnets, gateways, route tables)
2. **Configuration Storage**: Subnet IDs and other resource IDs are stored in configuration for use by other modules
3. **VPC Creation**: Creates a VPC with the specified CIDR block
4. **Internet Gateway**: Creates and attaches an Internet Gateway to the VPC
5. **Subnet Management**: Creates public and private subnets in each availability zone
6. **NAT Gateways**: Creates NAT Gateways for private subnet internet access
7. **Route Tables**: Configures public and private route tables with appropriate routes
8. **Tagging**: All resources are properly tagged for easy identification

## Configuration

The VPC configuration is managed through the [../config/aws_config.sh](../config/aws_config.sh) file which defines:
- Region
- Availability zones
- VPC CIDR block
- Subnet CIDR patterns
- Project naming conventions

Resource IDs are stored in the [../config/subnet_config.sh](../config/subnet_config.sh) file for use by other modules:
- Subnet IDs
- NAT Gateway IDs
- Internet Gateway IDs
- Route Table IDs
- VPC ID

## Resource Naming Convention

All resources follow a consistent naming pattern:
- VPC: `{project}-vpc`
- Internet Gateway: `{project}-igw`
- Public Subnets: `{project}-public-subnet-az{number}`
- Private Subnets: `{project}-private-subnet-az{number}`
- Public Route Tables: `{project}-public-rt`
- Private Route Tables: `{project}-private-rt-az{number}`
- NAT Gateways: `{project}-natgw-az{number}`

## Cleanup

To remove all VPC resources, use the cleanup script:
```bash
./vpc_cleanup.sh --vpc-id vpc-xxxxxxxx --region us-east-1
```