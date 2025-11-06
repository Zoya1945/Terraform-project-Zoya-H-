# Terraform Basics - Complete Guide

## What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp. It allows you to define and provision infrastructure using a declarative configuration language called HCL (HashiCorp Configuration Language).

## Core Concepts

### 1. **Declarative vs Imperative**

#### Declarative (Terraform)
```hcl
# You describe WHAT you want
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  count         = 3
}
```

#### Imperative (Traditional Scripts)
```bash
# You describe HOW to do it
for i in {1..3}; do
  aws ec2 run-instances --image-id ami-12345678 --instance-type t2.micro
done
```

### 2. **Infrastructure as Code Benefits**
- **Version Control**: Track changes over time
- **Collaboration**: Team can work together
- **Reusability**: Same code for multiple environments
- **Consistency**: Same result every time
- **Automation**: Integrate with CI/CD pipelines

## Terraform Workflow

### The Core Workflow
```
Write → Plan → Apply → Destroy
```

### 1. **Write Configuration**
```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "HelloWorld"
  }
}
```

### 2. **Initialize**
```bash
terraform init
```
- Downloads required providers
- Initializes backend
- Prepares working directory

### 3. **Plan**
```bash
terraform plan
```
- Shows what will be created/modified/destroyed
- Dry-run before actual changes
- Saves execution plan

### 4. **Apply**
```bash
terraform apply
```
- Executes the plan
- Creates/modifies infrastructure
- Updates state file

### 5. **Destroy**
```bash
terraform destroy
```
- Removes all managed infrastructure
- Cleans up resources

## Terraform Files

### 1. **Configuration Files (.tf)**
```hcl
# main.tf - Main configuration
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

# variables.tf - Input variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# outputs.tf - Output values
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

### 2. **State File (terraform.tfstate)**
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-12345678",
            "instance_type": "t2.micro",
            "public_ip": "203.0.113.12"
          }
        }
      ]
    }
  ]
}
```

### 3. **Variable Files (.tfvars)**
```hcl
# terraform.tfvars
instance_type = "t3.micro"
environment   = "production"
region        = "us-west-2"
```

### 4. **Lock File (.terraform.lock.hcl)**
```hcl
# This file is maintained automatically by "terraform init".
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:ltxyuBWIy9cq0k9gMdIvLaM56YZ9+W8TSgWD/+7+QK0=",
  ]
}
```

## HCL Syntax Basics

### 1. **Blocks**
```hcl
# Block type "block_label" "block_label" {
#   argument = value
# }

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
```

### 2. **Arguments**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"    # String
  instance_type = "t2.micro"       # String
  count         = 2                # Number
  monitoring    = true             # Boolean
  
  tags = {                         # Map
    Name = "WebServer"
    Env  = "Production"
  }
  
  security_groups = [              # List
    "web-sg",
    "ssh-sg"
  ]
}
```

### 3. **Comments**
```hcl
# Single line comment

/*
Multi-line
comment
*/

resource "aws_instance" "web" {
  ami           = "ami-12345678"  # Inline comment
  instance_type = "t2.micro"
}
```

### 4. **Expressions**
```hcl
# String interpolation
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.instance_type
  
  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# Conditional expressions
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
}

# Function calls
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = merge(
    var.common_tags,
    {
      Name = "WebServer"
    }
  )
}
```

## Resource Blocks

### Basic Resource
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
resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t2.micro"
  key_name               = "my-key"
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  
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

### Resource Dependencies
```hcl
# Implicit dependency (reference)
resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id  # Implicit dependency on VPC
}

# Explicit dependency
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  depends_on = [
    aws_security_group.web,
    aws_subnet.public
  ]
}
```

## Data Sources

### Fetching Existing Resources
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
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_vpc.default.id
}
```

## Variables

### Input Variables
```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}
```

### Using Variables
```hcl
resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = "ami-12345678"
  instance_type          = var.instance_type
  monitoring             = var.enable_monitoring
  availability_zone      = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-web-${count.index + 1}"
  })
}
```

### Local Values
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "MyProject"
    ManagedBy   = "Terraform"
  }
  
  instance_name = "${var.environment}-web-server"
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = local.instance_name
  })
}
```

## Outputs

### Output Values
```hcl
# outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
  sensitive   = false
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}
```

### Using Outputs
```bash
# View all outputs
terraform output

# View specific output
terraform output instance_public_ip

# Output in JSON format
terraform output -json
```

## Terraform Commands

### Essential Commands
```bash
# Initialize working directory
terraform init

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Show execution plan
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List resources in state
terraform state list

# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0
```

### Advanced Commands
```bash
# Refresh state
terraform refresh

# Target specific resource
terraform apply -target=aws_instance.web

# Use specific var file
terraform apply -var-file="prod.tfvars"

# Set variable from command line
terraform apply -var="instance_type=t3.micro"

# Generate dependency graph
terraform graph | dot -Tpng > graph.png

# Workspace commands
terraform workspace list
terraform workspace new prod
terraform workspace select prod
```

## Best Practices

### 1. **File Organization**
```
project/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider versions
├── terraform.tfvars # Variable values
└── modules/         # Reusable modules
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### 2. **Naming Conventions**
```hcl
# Use descriptive names
resource "aws_instance" "web_server" {  # Good
  # ...
}

resource "aws_instance" "i1" {          # Bad
  # ...
}

# Use consistent naming
variable "instance_type" {              # Good - snake_case
variable "instanceType" {               # Bad - camelCase
```

### 3. **Resource Tagging**
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
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

### 4. **Version Constraints**
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Common Patterns

### 1. **Multi-Environment Setup**
```hcl
# environments/dev/main.tf
module "infrastructure" {
  source = "../../modules/infrastructure"
  
  environment     = "dev"
  instance_type   = "t2.micro"
  instance_count  = 1
}

# environments/prod/main.tf
module "infrastructure" {
  source = "../../modules/infrastructure"
  
  environment     = "prod"
  instance_type   = "t3.large"
  instance_count  = 3
}
```

### 2. **Conditional Resources**
```hcl
resource "aws_instance" "web" {
  count = var.create_instance ? 1 : 0
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

resource "aws_eip" "web" {
  count = var.create_instance && var.assign_eip ? 1 : 0
  
  instance = aws_instance.web[0].id
  domain   = "vpc"
}
```

### 3. **Dynamic Blocks**
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
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
```

## Troubleshooting

### Common Errors

#### 1. **Resource Already Exists**
```bash
Error: resource already exists

# Solution: Import existing resource
terraform import aws_instance.web i-1234567890abcdef0
```

#### 2. **State Lock**
```bash
Error: state locked

# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

#### 3. **Provider Not Found**
```bash
Error: provider not found

# Solution: Run terraform init
terraform init
```

### Debug Mode
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Log to file
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform apply
```

## Conclusion

Terraform basics provide the foundation for Infrastructure as Code. Understanding resources, variables, outputs, and the core workflow is essential for building and managing infrastructure effectively. Start with simple configurations and gradually adopt more advanced patterns as you become comfortable with the basics.