#!/bin/bash

# Main VPC Creation Script
# Usage: ./main.sh --project <project_name> --region <region> --azs <availability_zones> [other options]

# Source the function libraries
source ../config/aws_config.sh
source ../config/subnet_config.sh
source ./vpc_manage.sh

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT_NAME="$2"; shift ;;
        --region) REGION="$2"; shift ;;
        --azs) AVAILABILITY_ZONES="$2"; shift ;;
        --profile) IAM_PROFILE="$2"; shift ;;
        --action) ACTION="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

main() {
    echo "Starting VPC infrastructure creation..."
    
    # Set default action
    ACTION=${ACTION:-"all"}
    
    case $ACTION in
        "vpc")
            # Load configurations
            load_aws_config
            init_subnet_config
            
            # Override with command line parameters if provided
            export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
            export REGION=${REGION:-$REGION}
            export AVAILABILITY_ZONES=${AVAILABILITY_ZONES:-$AVAILABILITY_ZONES}
            export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
            
            # Initialize VPC only
            echo "1. Initializing VPC..."
            init_vpc
            echo "VPC initialization completed"
            ;;
            
        "subnets")
            # Load configurations
            load_aws_config
            init_subnet_config
            
            # Override with command line parameters if provided
            export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
            export REGION=${REGION:-$REGION}
            export AVAILABILITY_ZONES=${AVAILABILITY_ZONES:-$AVAILABILITY_ZONES}
            export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
            
            # Create subnets only
            echo "1. Creating subnets..."
            create_all_subnets
            echo "Subnet creation completed"
            ;;
            
        "gateways")
            # Load configurations
            load_aws_config
            init_subnet_config
            
            # Override with command line parameters if provided
            export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
            export REGION=${REGION:-$REGION}
            export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
            
            # Create gateways only
            echo "1. Creating gateways..."
            create_all_gateways
            echo "Gateway creation completed"
            ;;
            
        "routes")
            # Load configurations
            load_aws_config
            init_subnet_config
            
            # Override with command line parameters if provided
            export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
            export REGION=${REGION:-$REGION}
            export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
            
            # Create route tables only
            echo "1. Creating route tables..."
            create_all_route_tables
            echo "Route table creation completed"
            ;;
            
        "all"|*)
            # Load configurations
            load_aws_config
            init_subnet_config
            
            # Override with command line parameters if provided
            export PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME}
            export REGION=${REGION:-$REGION}
            export AVAILABILITY_ZONES=${AVAILABILITY_ZONES:-$AVAILABILITY_ZONES}
            export IAM_PROFILE=${IAM_PROFILE:-$IAM_PROFILE}
            
            # Initialize VPC infrastructure
            echo "1. Initializing network infrastructure..."
            init_network_infrastructure
            echo "VPC infrastructure initialization completed"
            ;;
    esac
    
    echo "VPC setup completed for project: $PROJECT_NAME"
}

main "$@"