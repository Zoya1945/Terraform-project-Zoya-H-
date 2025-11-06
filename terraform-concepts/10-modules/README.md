# Terraform Modules - Complete Guide

## What are Modules?

Modules in Terraform are containers for multiple resources that are used together. They allow you to create reusable components and organize your Terraform code into logical groups.

## Module Structure

### Basic Module Structure
```
modules/
└── vpc/
    ├── main.tf          # Main resource definitions
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    ├── versions.tf      # Provider requirements
    └── README.md        # Documentation
```

### Advanced Module Structure
```
modules/
└── web-application/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── README.md
    ├── examples/
    │   └── complete/
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    └── modules/
        ├── alb/
        ├── asg/
        └── security-groups/
```

## Creating a Module

### 1. **Simple VPC Module**

#### modules/vpc/main.tf
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(var.tags, {
    Name = var.name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_igw ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Type = "Private"
  })
}

# Route Tables
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each = var.create_igw ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main[0].id
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}
```

#### modules/vpc/variables.tf
```hcl
variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
  default     = "vpc"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
```

#### modules/vpc/outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = try(aws_route_table.public[0].id, null)
}

output "availability_zones" {
  description = "List of availability zones of subnets"
  value       = var.availability_zones
}
```

#### modules/vpc/versions.tf
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
```

## Using Modules

### 1. **Local Module Usage**
```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  create_igw = true
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}

# Use module outputs
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
  
  tags = {
    Name = "web-server"
  }
}
```

### 2. **Remote Module Usage**
```hcl
# From Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
  
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# From Git repository
module "security_group" {
  source = "git::https://github.com/company/terraform-modules.git//security-group?ref=v1.0.0"
  
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id
  
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

### 3. **Module with Count**
```hcl
module "web_servers" {
  count = var.environment == "prod" ? 3 : 1
  
  source = "./modules/web-server"
  
  name          = "web-${count.index + 1}"
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[count.index % length(module.vpc.public_subnet_ids)]
}
```

### 4. **Module with For Each**
```hcl
module "databases" {
  for_each = var.databases
  
  source = "./modules/rds"
  
  name           = each.key
  engine         = each.value.engine
  instance_class = each.value.instance_class
  subnet_ids     = module.vpc.private_subnet_ids
  
  tags = merge(var.common_tags, {
    Database = each.key
  })
}

variable "databases" {
  type = map(object({
    engine         = string
    instance_class = string
  }))
  default = {
    app = {
      engine         = "mysql"
      instance_class = "db.t3.micro"
    }
    analytics = {
      engine         = "postgres"
      instance_class = "db.t3.small"
    }
  }
}
```

## Advanced Module Patterns

### 1. **Conditional Resources in Modules**
```hcl
# modules/web-app/main.tf
resource "aws_lb" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
}

resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.create_load_balancer ? [aws_lb_target_group.main[0].arn] : []
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
}

resource "aws_lb_target_group" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
```

### 2. **Module Composition**
```hcl
# modules/complete-app/main.tf
module "vpc" {
  source = "../vpc"
  
  name               = var.name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "security_groups" {
  source = "../security-groups"
  
  name   = var.name
  vpc_id = module.vpc.vpc_id
  
  ingress_rules = var.security_rules
}

module "web_app" {
  source = "../web-app"
  
  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_ids   = [module.security_groups.web_sg_id]
  create_load_balancer = var.create_load_balancer
}
```

### 3. **Module with Dynamic Blocks**
```hcl
# modules/security-group/main.tf
resource "aws_security_group" "main" {
  name_prefix = "${var.name}-"
  vpc_id      = var.vpc_id
  description = var.description
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }
  
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", null)
    }
  }
  
  tags = merge(var.tags, {
    Name = var.name
  })
}
```

## Module Versioning

### 1. **Git Tags**
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//vpc?ref=v1.2.0"
  
  # Module configuration
}
```

### 2. **Terraform Registry Versions**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Allow patch updates
  
  # Module configuration
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = ">= 5.0, < 6.0"  # Version range
  
  # Module configuration
}
```

### 3. **Version Constraints**
```hcl
# Exact version
version = "= 1.2.0"

# Minimum version
version = ">= 1.2.0"

# Pessimistic constraint
version = "~> 1.2.0"  # >= 1.2.0, < 1.3.0

# Version range
version = ">= 1.2.0, < 2.0.0"
```

## Module Testing

### 1. **Example Configurations**
```hcl
# examples/complete/main.tf
module "complete_example" {
  source = "../../"
  
  name               = "complete-example"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  
  tags = {
    Environment = "test"
    Example     = "complete"
  }
}

output "vpc_id" {
  value = module.complete_example.vpc_id
}
```

### 2. **Terratest (Go)**
```go
// test/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
        Vars: map[string]interface{}{
            "name": "test-vpc",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

### 3. **Kitchen-Terraform**
```yaml
# .kitchen.yml
driver:
  name: terraform

provisioner:
  name: terraform

platforms:
  - name: aws

suites:
  - name: default
    driver:
      root_module_directory: test/fixtures/default
    verifier:
      name: awspec
```

## Module Documentation

### 1. **README Template**
```markdown
# VPC Module

This module creates a VPC with public and private subnets.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name               = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for resources | `string` | `"vpc"` | no |
| cidr_block | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
```

### 2. **Auto-generated Documentation**
```bash
# Install terraform-docs
brew install terraform-docs

# Generate documentation
terraform-docs markdown table . > README.md
```

## Module Best Practices

### 1. **Module Structure**
```
modules/
└── my-module/
    ├── main.tf          # Primary resources
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    ├── versions.tf      # Provider requirements
    ├── README.md        # Documentation
    ├── examples/        # Usage examples
    │   ├── complete/
    │   └── simple/
    └── test/           # Tests
        └── module_test.go
```

### 2. **Variable Validation**
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}
```

### 3. **Output Descriptions**
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

### 4. **Tagging Strategy**
```hcl
locals {
  default_tags = {
    ManagedBy = "terraform"
    Module    = "vpc"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  
  tags = merge(local.default_tags, var.tags, {
    Name = var.name
  })
}
```

## Module Registry

### 1. **Publishing to Terraform Registry**
```hcl
# Repository structure for registry
terraform-aws-vpc/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── LICENSE
└── examples/
    └── complete/
        ├── main.tf
        └── README.md
```

### 2. **Module Naming Convention**
```
terraform-<PROVIDER>-<NAME>
terraform-aws-vpc
terraform-azurerm-network
terraform-google-gke
```

### 3. **Version Tags**
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Troubleshooting Modules

### Common Issues

#### 1. **Module Not Found**
```bash
# Error: Module not found
# Solution: Check source path and run terraform init
terraform init
```

#### 2. **Version Conflicts**
```bash
# Error: Module version conflict
# Solution: Update version constraints
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Update version
}
```

#### 3. **Output Not Available**
```bash
# Error: Output not defined
# Solution: Check module outputs.tf file
output "vpc_id" {
  value = aws_vpc.main.id
}
```

### Debug Modules
```bash
# Show module details
terraform show

# Graph module dependencies
terraform graph | dot -Tpng > graph.png

# Validate module
terraform validate
```

## Conclusion

Modules are essential for creating reusable, maintainable Terraform code. They promote code reuse, enforce standards, and simplify complex infrastructure management. Follow best practices for module structure, documentation, testing, and versioning to create high-quality, reliable modules.