# General Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ec2-project"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "DevOps Team"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks for admin access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP
}

# Instance Variables
variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for app tier"
  type        = string
  default     = "t3.small"
}

variable "spot_max_price" {
  description = "Maximum price for spot instances"
  type        = string
  default     = "0.05"
}

variable "public_key_path" {
  description = "Path to public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Load Balancer Variables
variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "example.com"
}

# Auto Scaling Variables
variable "web_min_size" {
  description = "Minimum number of web instances"
  type        = number
  default     = 1
}

variable "web_max_size" {
  description = "Maximum number of web instances"
  type        = number
  default     = 5
}

variable "web_desired_capacity" {
  description = "Desired number of web instances"
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "Minimum number of app instances"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum number of app instances"
  type        = number
  default     = 3
}

variable "app_desired_capacity" {
  description = "Desired number of app instances"
  type        = number
  default     = 2
}

# Monitoring Variables
variable "notification_email" {
  description = "Email for notifications"
  type        = string
  default     = "admin@example.com"
}