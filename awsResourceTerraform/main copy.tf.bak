# AWS Infrastructure with Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  name               = var.project_name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  
  vpc_id      = module.vpc.vpc_id
  project_name = var.project_name
}

# NAT Gateway Module
module "nat_gateway" {
  source = "./modules/nat-gateway"
  
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  project_name       = var.project_name
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = module.security_groups.security_group_ids
  key_name            = var.key_pair_name
  instance_type       = var.ec2_instance_type
  ami_id              = var.ec2_ami_id
  project_name        = var.project_name
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = module.security_groups.security_group_ids
  project_name        = var.project_name
  db_instance_class   = var.db_instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
}

# S3 Module
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
}

# CDN Module
module "cdn" {
  source = "./modules/cdn"
  
  s3_bucket_domain_name = module.s3.bucket_domain_name
  project_name          = var.project_name
}