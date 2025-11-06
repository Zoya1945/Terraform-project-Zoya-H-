# Terraform Resources - Complete Guide

## What are Resources?

Resources are the most important element in Terraform. They describe infrastructure objects like virtual machines, DNS records, or databases. Resources define what infrastructure you want to create, update, or delete.

## Resource Syntax

### Basic Structure
```hcl
resource "resource_type" "resource_name" {
  argument1 = value1
  argument2 = value2
  
  nested_block {
    nested_argument = nested_value
  }
}
```

### Real Example
```hcl
resource "aws_instance" "web_server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  key_name      = "my-keypair"
  
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id              = "subnet-12345678"
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  
  tags = {
    Name        = "WebServer"
    Environment = "Production"
  }
}
```

## Resource Types

### 1. **Managed Resources**
Resources that Terraform creates and manages
```hcl
# AWS EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

# AWS S3 Bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-terraform-bucket"
}

# AWS VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

### 2. **Data Sources**
Read-only resources that fetch information
```hcl
# Get existing VPC
data "aws_vpc" "default" {
  default = true
}

# Get latest AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use data source in resource
resource "aws_instance" "web" {
  ami       = data.aws_ami.amazon_linux.id
  subnet_id = data.aws_vpc.default.id
}
```

## Resource Arguments

### 1. **Required Arguments**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"  # Required
  instance_type = "t2.micro"     # Required
}
```

### 2. **Optional Arguments**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Optional arguments
  key_name               = "my-keypair"
  monitoring             = true
  associate_public_ip_address = true
  disable_api_termination = false
}
```

### 3. **Nested Blocks**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Nested block
  root_block_device {
    volume_type           = "gp3"
    volume_size          = 20
    delete_on_termination = true
    encrypted            = true
  }
  
  # Multiple nested blocks
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 100
  }
  
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_type = "io1"
    volume_size = 50
    iops        = 1000
  }
}
```

## Resource Meta-Arguments

### 1. **count**
Create multiple instances of a resource
```hcl
resource "aws_instance" "web" {
  count = 3
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

# Reference specific instance
output "first_instance_ip" {
  value = aws_instance.web[0].public_ip
}

# Reference all instances
output "all_instance_ips" {
  value = aws_instance.web[*].public_ip
}
```

### 2. **for_each**
Create resources based on a map or set
```hcl
# Using set
resource "aws_instance" "web" {
  for_each = toset(["web", "app", "db"])
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "${each.key}-server"
    Role = each.key
  }
}

# Using map
resource "aws_instance" "servers" {
  for_each = {
    web = "t2.micro"
    app = "t2.small"
    db  = "t2.medium"
  }
  
  ami           = "ami-12345678"
  instance_type = each.value
  
  tags = {
    Name = "${each.key}-server"
    Type = each.value
  }
}

# Reference specific instance
output "web_server_ip" {
  value = aws_instance.web["web"].public_ip
}
```

### 3. **depends_on**
Explicit dependencies between resources
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Explicit dependency
  depends_on = [
    aws_security_group.web,
    aws_subnet.public
  ]
}

resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 4. **provider**
Specify which provider configuration to use
```hcl
# Default provider
provider "aws" {
  region = "us-west-2"
}

# Aliased provider
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

# Use specific provider
resource "aws_instance" "west" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  # Uses default provider (us-west-2)
}

resource "aws_instance" "east" {
  provider = aws.east
  
  ami           = "ami-87654321"
  instance_type = "t2.micro"
  # Uses aliased provider (us-east-1)
}
```

### 5. **lifecycle**
Control resource lifecycle behavior
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    
    # Create new before destroying old
    create_before_destroy = true
    
    # Ignore changes to specific attributes
    ignore_changes = [
      ami,
      user_data
    ]
    
    # Replace resource when condition is met
    replace_triggered_by = [
      null_resource.trigger
    ]
  }
}
```

## Resource Addressing

### 1. **Resource References**
```hcl
# Reference resource attribute
resource "aws_security_group" "web" {
  name_prefix = "web-"
}

resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
}

# Reference with count
resource "aws_instance" "web" {
  count = 3
  # ...
}

output "instance_ips" {
  value = [
    aws_instance.web[0].public_ip,
    aws_instance.web[1].public_ip,
    aws_instance.web[2].public_ip
  ]
}

# Reference with for_each
resource "aws_instance" "servers" {
  for_each = toset(["web", "app"])
  # ...
}

output "web_server_ip" {
  value = aws_instance.servers["web"].public_ip
}
```

### 2. **Self References**
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true  # Reference to same security group
  }
}
```

## Resource Behavior

### 1. **Create**
```hcl
# New resource will be created
resource "aws_instance" "new_server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
```

### 2. **Update**
```hcl
# Existing resource will be updated in-place
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.small"  # Changed from t2.micro
  
  tags = {
    Name        = "WebServer"
    Environment = "Production"  # Added new tag
  }
}
```

### 3. **Replace**
```hcl
# Resource will be destroyed and recreated
resource "aws_instance" "web" {
  ami           = "ami-87654321"  # Changed AMI (forces replacement)
  instance_type = "t2.micro"
}
```

### 4. **Destroy**
```hcl
# Resource will be destroyed (removed from configuration)
# resource "aws_instance" "old_server" {
#   ami           = "ami-12345678"
#   instance_type = "t2.micro"
# }
```

## Advanced Resource Patterns

### 1. **Conditional Resources**
```hcl
# Create resource only in production
resource "aws_cloudwatch_log_group" "app_logs" {
  count = var.environment == "prod" ? 1 : 0
  
  name              = "/aws/application/myapp"
  retention_in_days = 30
}

# Using for_each for conditional creation
resource "aws_instance" "optional" {
  for_each = var.create_instances ? toset(["web", "app"]) : toset([])
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "${each.key}-server"
  }
}
```

### 2. **Dynamic Blocks**
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Static egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Variable for dynamic blocks
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
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
    }
  ]
}
```

### 3. **Resource Modules**
```hcl
# Module definition (modules/web-server/main.tf)
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = var.tags
}

resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

# Module usage
module "web_servers" {
  source = "./modules/web-server"
  
  ami_id        = "ami-12345678"
  instance_type = "t2.micro"
  name_prefix   = "prod-web"
  
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  tags = {
    Environment = "production"
    Team        = "web"
  }
}
```

## Resource Import

### Importing Existing Resources
```bash
# Import existing AWS instance
terraform import aws_instance.web i-1234567890abcdef0

# Import with count
terraform import 'aws_instance.web[0]' i-1234567890abcdef0

# Import with for_each
terraform import 'aws_instance.servers["web"]' i-1234567890abcdef0
```

### Import Block (Terraform 1.5+)
```hcl
# Import block
import {
  to = aws_instance.web
  id = "i-1234567890abcdef0"
}

# Resource configuration
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Configuration must match existing resource
}
```

## Resource Validation

### 1. **Built-in Validation**
```hcl
variable "instance_type" {
  type = string
  
  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 type."
  }
}
```

### 2. **Custom Validation**
```hcl
variable "cidr_block" {
  type = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "environment" {
  type = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Best Practices

### 1. **Resource Naming**
```hcl
# Use descriptive names
resource "aws_instance" "web_server" {}      # Good
resource "aws_instance" "i1" {}              # Bad

# Use consistent naming convention
resource "aws_instance" "web_server" {}
resource "aws_security_group" "web_server" {}
resource "aws_lb" "web_server" {}
```

### 2. **Resource Organization**
```hcl
# Group related resources
# networking.tf
resource "aws_vpc" "main" {}
resource "aws_subnet" "public" {}
resource "aws_internet_gateway" "main" {}

# compute.tf
resource "aws_instance" "web" {}
resource "aws_launch_template" "web" {}
resource "aws_autoscaling_group" "web" {}

# security.tf
resource "aws_security_group" "web" {}
resource "aws_security_group" "db" {}
```

### 3. **Resource Tagging**
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = merge(local.common_tags, {
    Name = "web-server"
    Role = "webserver"
  })
}
```

### 4. **Error Handling**
```hcl
# Use try() for safe operations
locals {
  instance_name = try(var.instance_config.name, "default-name")
}

# Use lifecycle rules for safety
resource "aws_instance" "critical" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  lifecycle {
    prevent_destroy = true
  }
}
```

## Troubleshooting Resources

### Common Issues

#### 1. **Resource Not Found**
```bash
# Error: Resource not found
# Solution: Check resource exists and permissions
terraform refresh
```

#### 2. **Dependency Cycle**
```bash
# Error: Cycle in resource dependencies
# Solution: Remove circular dependencies or use depends_on
```

#### 3. **Resource Already Exists**
```bash
# Error: Resource already exists
# Solution: Import existing resource
terraform import aws_instance.web i-1234567890abcdef0
```

### Debug Resources
```bash
# Show resource details
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Plan with detailed output
terraform plan -detailed-exitcode
```

## Conclusion

Resources are the core building blocks of Terraform configurations. Understanding resource syntax, meta-arguments, lifecycle management, and best practices is essential for effective infrastructure management. Use appropriate resource patterns, follow naming conventions, and implement proper validation to create maintainable and reliable infrastructure code.