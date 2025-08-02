# AWS Security Group Management

This directory contains scripts for managing security groups in AWS.

## Directory Structure

```
security/
├── security_manage.sh    # Main security group management functions
├── main.sh               # Main script to manage security groups
└── README.md             # This file
```

## Usage

To manage security groups, you can either run the main initialization script from the root directory or use the security-specific script:

### Using the global script (from aws directory)
```bash
# This is typically run as part of the main_init.sh process
./main_init.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp
```

### Using the security-specific script (from security directory)
```bash
cd security
./main.sh --region us-east-1 --project myapp --vpc-id vpc-xxxxxxxx
```

## Features

1. **Security Group Creation**: Creates security groups based on configuration
2. **Rule Management**: Adds inbound rules to security groups
3. **Tagging**: Security groups are named following the project naming convention
4. **Configuration-based**: Rules are defined in the configuration file
5. **VPC ID Handling**: Can accept VPC ID as parameter or read from shared configuration

## Configuration

Security group configurations are managed through the [../config/aws_config.sh](../config/aws_config.sh) file which defines:
- Security group templates with names and rules
- Protocol, port, and source CIDR for each rule

Example configuration:
```bash
export Security_LIST='[
  {"name": "proxy-web", "rules": [{"protocol": "TCP","port": 5601,"source": "10.3.0.0/16"}]},
  {"name": "redis", "rules": [{"protocol": "TCP","port": 6379,"source": "10.3.0.0/16"}]},
  {"name": "WireVpn", "rules": [{"protocol": "TCP","port": "10034-10040","source": "10.3.0.0/16"}]}
]'
```

## Resource Naming Convention

Security groups follow the naming pattern: `{project}-{security-group-name}`

For example, with project name "myapp":
- `myapp-proxy-web`
- `myapp-redis`

## VPC ID Handling

The security group management script can obtain the VPC ID in two ways:

1. **As a parameter**: Pass the VPC ID directly to the script
   ```bash
   ./main.sh --region us-east-1 --project myapp --vpc-id vpc-xxxxxxxx
   ```

2. **From shared configuration**: If the VPC has been created using the VPC module, 
   the VPC ID will be automatically retrieved from the shared configuration file.
   This requires that the VPC creation process has saved the VPC ID using the 
   `save_vpc_id` function in [../config/subnet_config.sh](../config/subnet_config.sh).

## Prerequisites

Before running the security group management script, you need:
1. An existing VPC (created with the VPC management scripts)
2. The VPC ID for that VPC (either provided as parameter or stored in configuration)
3. Proper AWS credentials configured