# Data Sources Examples

# Get current AWS account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get specific subnet (first available)
data "aws_subnet" "first" {
  id = data.aws_subnets.default.ids[0]
}

# Get security groups
data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# External data source - get current IP
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Template file example
data "template_file" "user_data" {
  template = <<-EOF
    #!/bin/bash
    echo "Instance started in ${region}" > /tmp/info.txt
    echo "Account: ${account_id}" >> /tmp/info.txt
    echo "AMI: ${ami_id}" >> /tmp/info.txt
  EOF
  
  vars = {
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
    ami_id     = data.aws_ami.amazon_linux.id
  }
}

# Use data sources in resource
resource "aws_instance" "example" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.first.id
  vpc_security_group_ids = data.aws_security_groups.default.ids
  
  user_data = data.template_file.user_data.rendered
  
  tags = {
    Name      = "DataSource-Example"
    Account   = data.aws_caller_identity.current.account_id
    Region    = data.aws_region.current.name
    AMI       = data.aws_ami.amazon_linux.name
    MyIP      = chomp(data.http.my_ip.response_body)
  }
}

# Outputs to show data source values
output "account_info" {
  description = "Current AWS account information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    user_id    = data.aws_caller_identity.current.user_id
    arn        = data.aws_caller_identity.current.arn
  }
}

output "region_info" {
  description = "Current region information"
  value = {
    name        = data.aws_region.current.name
    description = data.aws_region.current.description
  }
}

output "ami_info" {
  description = "Selected AMI information"
  value = {
    id           = data.aws_ami.amazon_linux.id
    name         = data.aws_ami.amazon_linux.name
    description  = data.aws_ami.amazon_linux.description
    architecture = data.aws_ami.amazon_linux.architecture
  }
}

output "vpc_info" {
  description = "Default VPC information"
  value = {
    id         = data.aws_vpc.default.id
    cidr_block = data.aws_vpc.default.cidr_block
    state      = data.aws_vpc.default.state
  }
}

output "availability_zones" {
  description = "Available availability zones"
  value       = data.aws_availability_zones.available.names
}

output "my_ip" {
  description = "Current public IP address"
  value       = chomp(data.http.my_ip.response_body)
}