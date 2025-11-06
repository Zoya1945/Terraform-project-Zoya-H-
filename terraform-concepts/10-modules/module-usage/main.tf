# Module Usage Examples

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Example 1: Basic module usage
module "web_server_basic" {
  source = "../example-module"
  
  name         = "basic-web"
  ami_id       = data.aws_ami.amazon_linux.id
  subnet_ids   = data.aws_subnets.default.ids
  
  tags = {
    Environment = "development"
    Purpose     = "basic-example"
  }
}

# Example 2: Multiple instances with EIP
module "web_server_advanced" {
  source = "../example-module"
  
  name           = "advanced-web"
  instance_count = 2
  instance_type  = "t3.small"
  ami_id         = data.aws_ami.amazon_linux.id
  subnet_ids     = data.aws_subnets.default.ids
  create_eip     = true
  
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
  
  tags = {
    Environment = "production"
    Purpose     = "advanced-example"
  }
}

# Example 3: Module with for_each
module "environment_servers" {
  for_each = var.environments
  
  source = "../example-module"
  
  name           = "${each.key}-web"
  instance_count = each.value.instance_count
  instance_type  = each.value.instance_type
  ami_id         = data.aws_ami.amazon_linux.id
  subnet_ids     = data.aws_subnets.default.ids
  create_eip     = each.value.create_eip
  
  tags = merge(var.common_tags, {
    Environment = each.key
  })
}

# Variables for for_each example
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    instance_count = number
    instance_type  = string
    create_eip     = bool
  }))
  default = {
    dev = {
      instance_count = 1
      instance_type  = "t3.micro"
      create_eip     = false
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      create_eip     = true
    }
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "module-example"
  }
}

# Outputs
output "basic_server_ips" {
  description = "Basic server IP addresses"
  value       = module.web_server_basic.instance_public_ips
}

output "advanced_server_details" {
  description = "Advanced server details"
  value       = module.web_server_advanced.instance_details
}

output "environment_servers" {
  description = "Environment server information"
  value = {
    for env, module_output in module.environment_servers : env => {
      instance_ids = module_output.instance_ids
      public_ips   = module_output.instance_public_ips
    }
  }
}