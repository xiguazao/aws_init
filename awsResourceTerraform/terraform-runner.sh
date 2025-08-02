#!/bin/bash

# Terraform Runner Script
# This script simplifies running Terraform commands in a Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose is not installed. Will use 'docker compose' instead."
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi

# Function to build the terraform container
build_container() {
    print_status "Building Terraform container..."
    $DOCKER_COMPOSE_CMD build
    print_status "Terraform container built successfully."
}

# Function to run terraform commands
run_terraform() {
    print_status "Running Terraform command: $*"
    $DOCKER_COMPOSE_CMD run --rm terraform terraform "$@"
}

# Function to initialize terraform
init_terraform() {
    print_status "Initializing Terraform..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform init "$@"
}

# Function to plan terraform changes
plan_terraform() {
    print_status "Planning Terraform changes..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform plan "$@"
}

# Function to apply terraform changes
apply_terraform() {
    print_status "Applying Terraform changes..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform apply "$@"
}

# Function to destroy terraform infrastructure
destroy_terraform() {
    print_status "Destroying Terraform infrastructure..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform destroy "$@"
}

# Function to get shell access to terraform container
shell_access() {
    print_status "Starting shell in Terraform container..."
    $DOCKER_COMPOSE_CMD run --rm terraform
}

# Function to validate terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform validate
}

# Function to format terraform files
format_terraform() {
    print_status "Formatting Terraform files..."
    $DOCKER_COMPOSE_CMD run --rm terraform terraform fmt "$@"
}

# Display help
show_help() {
    echo "Terraform Runner Script"
    echo "Usage: ./terraform-runner.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build        Build the Terraform container"
    echo "  init         Initialize Terraform"
    echo "  plan         Plan Terraform changes"
    echo "  apply        Apply Terraform changes"
    echo "  destroy      Destroy Terraform infrastructure"
    echo "  validate     Validate Terraform configuration"
    echo "  fmt          Format Terraform files"
    echo "  shell        Get shell access to Terraform container"
    echo "  help         Display this help message"
    echo ""
    echo "You can also pass any Terraform command directly:"
    echo "  ./terraform-runner.sh <terraform-command> [args...]"
    echo ""
    echo "Examples:"
    echo "  ./terraform-runner.sh init -reconfigure"
    echo "  ./terraform-runner.sh plan -out=tfplan"
    echo "  ./terraform-runner.sh apply tfplan"
}

# Main execution
case "${1:-}" in
    build)
        build_container
        ;;
    init)
        shift
        init_terraform "$@"
        ;;
    plan)
        shift
        plan_terraform "$@"
        ;;
    apply)
        shift
        apply_terraform "$@"
        ;;
    destroy)
        shift
        destroy_terraform "$@"
        ;;
    validate)
        shift
        validate_terraform "$@"
        ;;
    fmt)
        shift
        format_terraform "$@"
        ;;
    shell)
        shell_access
        ;;
    help|"")
        show_help
        ;;
    *)
        # Pass all arguments to terraform command
        run_terraform "$@"
        ;;
esac