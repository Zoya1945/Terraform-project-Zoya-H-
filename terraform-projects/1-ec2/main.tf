# Complete EC2 Infrastructure Project
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Local Values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# Include all modular configurations
# VPC and Networking are in vpc/ folder
# Security Groups are in security-groups/ folder
# Load Balancers are in load-balancer/ folder
# Auto Scaling is in auto-scaling/ folder
# Monitoring is in monitoring/ folder
# Backup is in backup/ folder