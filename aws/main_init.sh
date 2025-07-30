# Source the function libraries
# source ./aws_config.sh
source ./vpc/vpc_manage.sh
source ./security/security_manage.sh
source ./ec2/ec2_manage.sh


main() {
    # Initialize infrastructure
    echo "1. Initializing network infrastructure..."
    init_network_infrastructure
    echo "Initializing network infrastructure completed"
    

    # VPC_ID="vpc-001d3f44f5b81e7ba"    
    # Manage security groups
    echo "2. Create Managing security groups in $VPC_ID ..."
    manage_security_groups "$VPC_ID"
    echo "Security group management completed"

    # Create EC2 instances
    echo "3. Creating EC2 instances..."
    init_ec2_infrastructure
    echo "EC2 instance creation completed"

    echo "Infrastructure setup completed for project: $PROJECT_NAME"    
}

main "$@"

# aws configure

# ./main_init.sh --region us-east-1 --azs us-east-1a,us-east-1b --project myapp
# To create EC2 instances: cd ec2 && ./main.sh --project myapp [other options]