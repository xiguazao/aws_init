# AWS EC2 Instance Management

This directory contains scripts and configuration files for managing EC2 instances in AWS with separate configuration for images, instance types, VPCs, public access, key pairs, and more.

## Directory Structure

```
ec2/
├── ec2_config.sh         # Configuration file for EC2 instances
├── ec2_manage.sh         # Main EC2 management functions
├── main.sh               # Main script to create EC2 instances
└── README.md             # This file
```

## Configuration

The [ec2_config.sh](ec2_config.sh) file contains all the configurable parameters for EC2 instance creation:

- **EC2_REGION**: AWS region to deploy instances
- **EC2_INSTANCE_TYPE**: Type of EC2 instance (e.g., t3.micro)
- **EC2_AMI_ID**: Amazon Machine Image ID
- **EC2_KEY_PAIR_NAME**: Name of the key pair for SSH access
- **EC2_PROJECT_NAME**: Project name for tagging resources
- **EC2_SUBNET_TYPE**: Type of subnet (public or private)
- **EC2_AVAILABILITY_ZONE_NUM**: Which availability zone to use
- **EC2_SECURITY_GROUPS**: Comma-separated list of security groups
- **EC2_INSTANCE_NAME**: Name tag for the instance
- **EC2_VOLUME_SIZE**: Size of the root EBS volume in GB
- **EC2_SSH_USER**: SSH user for connecting to the instance
- **EC2_SSH_KEY_PATH**: Path to the SSH private key file

## Usage

To create an EC2 instance, run the main script with appropriate parameters:

```bash
# Basic usage with defaults
./main.sh --project myproject

# With custom parameters
./main.sh --project myproject \
          --region us-east-1 \
          --instance-type t3.small \
          --ami-id ami-12345678 \
          --key-pair my-key \
          --subnet-type public \
          --az-num 1 \
          --instance-name my-web-server \
          --security-groups sg-123,sg-456 \
          --volume-size 20
```

## Features

1. **Separate Configuration**: All configuration is separated from code for easy customization
2. **VPC Integration**: Automatically finds and uses the correct VPC and subnets based on project name
3. **Flexible Network Placement**: Can place instances in public or private subnets
4. **Security Group Support**: Can attach existing security groups to instances
5. **Automatic Tagging**: All instances are tagged with project and instance names
6. **Instance Information**: Automatically saves connection information to a file

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Existing VPC and subnets created (using the vpc_manage.sh script)
3. Key pair created in the AWS console or via CLI
4. Required security groups created

## Output

After successful instance creation, the script will output:
- Instance ID
- Public and private IP addresses
- SSH connection command
- A text file with instance information