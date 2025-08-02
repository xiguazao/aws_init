# AWS Infrastructure with Terraform

This project provisions a complete AWS infrastructure using Terraform, including VPC, subnets, security groups, NAT gateways, EC2 instances, RDS databases, S3 buckets, and CloudFront CDN.

## Architecture Overview

The infrastructure consists of:

1. **VPC** - Virtual Private Cloud with public and private subnets
2. **Security Groups** - Network access control for different tiers
3. **NAT Gateways** - Internet access for private subnet instances
4. **EC2 Instances** - Web and application servers
5. **RDS** - Managed database service
6. **S3** - Object storage
7. **CloudFront** - Content delivery network

## Directory Structure

```
terrform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration template
├── modules/             # Reusable modules
│   ├── vpc/             # VPC module
│   ├── security-groups/ # Security groups module
│   ├── nat-gateway/     # NAT gateway module
│   ├── ec2/             # EC2 instances module
│   ├── rds/             # RDS database module
│   ├── s3/              # S3 bucket module
│   └── cdn/             # CloudFront CDN module
└── README.md            # This file
```

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) >= 1.0
2. AWS CLI [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with appropriate credentials
3. An existing EC2 key pair in your AWS account

## Backend Configuration

This project includes a template for remote state storage in [backend.tf](backend.tf). By default, Terraform stores state locally, but for production use, it's recommended to use remote state storage.

To use remote state (e.g., S3):

1. Uncomment and customize the S3 backend section in [backend.tf](backend.tf)
2. Create the required S3 bucket and DynamoDB table (if using state locking)
3. Run `terraform init -reconfigure` to apply the backend configuration

Remote state provides:
- State sharing between team members
- State locking to prevent concurrent modifications
- State backup and versioning

## Modules

### VPC Module

Creates a VPC with public and private subnets across multiple availability zones.

**Resources:**
- VPC
- Internet Gateway
- Public and Private Subnets
- Public Route Table
- Route Table Associations

### Security Groups Module

Creates security groups for different tiers of the application:

**Resources:**
- Web Security Group (HTTP, HTTPS, SSH access)
- Application Security Group (internal communication)
- Database Security Group (MySQL access)

### NAT Gateway Module

Creates NAT gateways for internet access from private subnets:

**Resources:**
- Elastic IPs
- NAT Gateways
- Private Route Tables
- Route Table Associations

### EC2 Module

Creates EC2 instances for web and application servers:

**Resources:**
- Web Servers (in public subnets)
- Application Servers (in private subnets)

### RDS Module

Creates a managed MySQL database:

**Resources:**
- DB Subnet Group
- RDS Instance

### S3 Module

Creates an S3 bucket for object storage:

**Resources:**
- S3 Bucket
- Bucket ACL
- Bucket Versioning

### CDN Module

Creates a CloudFront distribution for content delivery:

**Resources:**
- CloudFront Distribution
- Origin Access Identity

## Usage

1. Clone or download this repository

2. Navigate to the terraform directory:
   ```bash
   cd terrform
   ```

3. (Optional) Configure remote state storage in [backend.tf](backend.tf)

4. Initialize Terraform:
   ```bash
   terraform init
   ```

5. Review the planned changes:
   ```bash
   terraform plan
   ```

6. Apply the configuration:
   ```bash
   terraform apply
   ```

7. To destroy the infrastructure when no longer needed:
   ```bash
   terraform destroy
   ```

## Configuration

The infrastructure can be customized through variables in [variables.tf](variables.tf):

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | us-east-1 |
| `project_name` | Project name for resource naming | HMBS |
| `vpc_cidr` | CIDR block for VPC | 10.0.0.0/16 |
| `availability_zones` | Availability zones | ["us-east-1a", "us-east-1b"] |
| `public_subnets` | Public subnet CIDR blocks | ["10.0.1.0/24", "10.0.2.0/24"] |
| `private_subnets` | Private subnet CIDR blocks | ["10.0.3.0/24", "10.0.4.0/24"] |
| `key_pair_name` | EC2 Key Pair name | my-key-pair |
| `ec2_instance_type` | EC2 instance type | t3.micro |
| `ec2_ami_id` | EC2 AMI ID | Amazon Linux 2 |
| `db_instance_class` | Database instance class | db.t3.micro |
| `db_name` | Database name | myappdb |
| `db_username` | Database username | admin |
| `db_password` | Database password | MySecurePassword123! |

## Outputs

After applying the configuration, Terraform will output the following information:

- VPC ID and CIDR block
- Public and private subnet IDs
- Security group IDs
- NAT Gateway IDs
- EC2 instance IDs and public IPs
- RDS endpoint and instance ID
- S3 bucket ID and domain name
- CloudFront domain name and distribution ID

## Architecture Diagram

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnets ───┐
    │             │
    ▼             ▼
Web Servers    NAT Gateways
    │             │
    ▼             ▼
Application  Private Subnets
  Servers          │
    │             ▼
    ▼         RDS Database
Internal
Communication
```

## Security

- Web servers are placed in public subnets with restricted inbound access
- Application servers are placed in private subnets with no direct internet access
- Database servers are in private subnets and only accessible from application servers
- All traffic between tiers is controlled by security groups

## High Availability

- Resources are distributed across multiple availability zones
- NAT gateways are deployed in each availability zone
- Each tier has instances in multiple availability zones

## Cost Optimization

- Uses cost-effective instance types by default
- Leverages AWS managed services (RDS, S3, CloudFront) to reduce operational overhead