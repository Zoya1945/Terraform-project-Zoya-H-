# Terraform Q&A - Interview Questions and Scenarios

This directory contains comprehensive Terraform interview questions, scenario-based problems, and their solutions organized by topics.

## Directory Structure

- **1-iac-history/** - Infrastructure as Code history and concepts
- **2-providers/** - Terraform providers questions
- **3-terraform-basics/** - Basic Terraform concepts and commands
- **4-hcl-syntax/** - HashiCorp Configuration Language syntax
- **5-resources/** - Resource management questions
- **6-variables/** - Variables and data types
- **7-data-sources/** - Data sources usage
- **8-state-management/** - State file management
- **9-backend/** - Backend configuration
- **10-modules/** - Module creation and usage
- **11-functions/** - Built-in functions
- **12-conditionals/** - Conditional expressions
- **13-loops/** - Loops and iterations
- **14-provisioners/** - Provisioners usage
- **15-workspaces/** - Workspace management
- **16-security/** - Security best practices
- **17-troubleshooting/** - Common issues and solutions
- **18-scenarios/** - Real-world scenarios and case studies

## Question Types

- **Basic Questions** - Fundamental concepts
- **Intermediate Questions** - Practical implementation
- **Advanced Questions** - Complex scenarios and best practices
- **Scenario-Based** - Real-world problem solving
- **Troubleshooting** - Debugging and issue resolution

## How to Use

Each folder contains:
- `questions.md` - Interview questions with answers
- `scenarios.md` - Practical scenarios and solutions
- `examples/` - Code examples and implementations

---

# Most Asked Scenario-Based Questions & Answers

## Scenario 1: State File Management Crisis
**Question:** Your team accidentally deleted the Terraform state file. How do you recover?

**Answer:**
```bash
# 1. Check for backup files
ls -la terraform.tfstate*

# 2. If backup exists, restore it
cp terraform.tfstate.backup terraform.tfstate

# 3. If no backup, recreate state by importing existing resources
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_security_group.web sg-1234567890abcdef0

# 4. Validate state matches configuration
terraform plan
```

## Scenario 2: Multi-Environment Deployment
**Question:** How do you manage the same infrastructure across dev, staging, and prod environments?

**Answer:**
```hcl
# Using workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Environment-specific configuration
locals {
  env_config = {
    dev = {
      instance_type = "t3.micro"
      instance_count = 1
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
    }
    prod = {
      instance_type = "t3.large"
      instance_count = 5
    }
  }
  
  config = local.env_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
  
  tags = {
    Name = "${terraform.workspace}-web-${count.index + 1}"
    Environment = terraform.workspace
  }
}
```

## Scenario 3: Resource Dependency Issues
**Question:** You're getting circular dependency errors. How do you resolve them?

**Answer:**
```hcl
# Problem: Circular dependency
resource "aws_security_group" "web" {
  ingress {
    security_groups = [aws_security_group.db.id]  # References db
  }
}

resource "aws_security_group" "db" {
  ingress {
    security_groups = [aws_security_group.web.id]  # References web
  }
}

# Solution: Use security group rules
resource "aws_security_group" "web" {
  name = "web-sg"
}

resource "aws_security_group" "db" {
  name = "db-sg"
}

resource "aws_security_group_rule" "web_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.db.id
}
```

## Scenario 4: Remote State Sharing
**Question:** Multiple teams need to share Terraform state. How do you implement this?

**Answer:**
```hcl
# Backend configuration for shared state
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Team A references Team B's infrastructure
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.networking.outputs.public_subnet_id
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.web_sg_id]
}
```

## Scenario 5: Infrastructure Drift Detection
**Question:** How do you detect and handle infrastructure drift?

**Answer:**
```bash
# 1. Detect drift
terraform plan -refresh-only

# 2. Update state to match reality (if changes are acceptable)
terraform apply -refresh-only

# 3. Or revert infrastructure to match configuration
terraform apply

# 4. Automated drift detection in CI/CD
#!/bin/bash
terraform plan -detailed-exitcode
if [ $? -eq 2 ]; then
  echo "Infrastructure drift detected!"
  # Send alert or auto-remediate
fi
```

## Scenario 6: Blue-Green Deployment
**Question:** Implement zero-downtime deployment using Terraform.

**Answer:**
```hcl
variable "environment_color" {
  description = "Current active environment (blue or green)"
  type        = string
  default     = "blue"
}

locals {
  active_color   = var.environment_color
  inactive_color = var.environment_color == "blue" ? "green" : "blue"
}

# Blue environment
module "blue_environment" {
  source = "./modules/app-environment"
  
  color          = "blue"
  is_active      = local.active_color == "blue"
  instance_count = local.active_color == "blue" ? 3 : 0
}

# Green environment
module "green_environment" {
  source = "./modules/app-environment"
  
  color          = "green"
  is_active      = local.active_color == "green"
  instance_count = local.active_color == "green" ? 3 : 0
}

# Load balancer target group attachment
resource "aws_lb_target_group_attachment" "active" {
  count = local.active_color == "blue" ? length(module.blue_environment.instance_ids) : length(module.green_environment.instance_ids)
  
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = local.active_color == "blue" ? module.blue_environment.instance_ids[count.index] : module.green_environment.instance_ids[count.index]
}
```

## Scenario 7: Module Versioning and Updates
**Question:** How do you safely update Terraform modules across environments?

**Answer:**
```hcl
# Use version constraints
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"  # Allow patch updates only
  
  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr
}

# For custom modules
module "app" {
  source = "git::https://github.com/company/terraform-modules.git//app?ref=v2.1.0"
  
  environment = var.environment
}

# Update strategy:
# 1. Test in dev first
# 2. Update version in dev.tfvars
# 3. Apply and validate
# 4. Promote to staging, then prod
```

## Scenario 8: Cost Optimization
**Question:** How do you implement cost optimization using Terraform?

**Answer:**
```hcl
# Scheduled scaling for non-production
resource "aws_autoscaling_schedule" "scale_down" {
  count = terraform.workspace != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-down-after-hours"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 0
  recurrence             = "0 18 * * MON-FRI"  # 6 PM weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_schedule" "scale_up" {
  count = terraform.workspace != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-up-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 3
  recurrence             = "0 8 * * MON-FRI"   # 8 AM weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# Environment-specific instance types
locals {
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }
}

resource "aws_instance" "web" {
  instance_type = local.instance_type[terraform.workspace]
}
```

## Scenario 9: Security Compliance
**Question:** How do you ensure all resources meet security compliance requirements?

**Answer:**
```hcl
# Enforce encryption
resource "aws_s3_bucket" "data" {
  bucket = "${var.project}-${terraform.workspace}-data"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Mandatory tags
locals {
  mandatory_tags = {
    Environment = terraform.workspace
    Project     = var.project_name
    Owner       = var.team_name
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "web" {
  tags = merge(local.mandatory_tags, {
    Name = "${terraform.workspace}-web-server"
  })
}
```

## Scenario 10: Disaster Recovery
**Question:** How do you implement disaster recovery with Terraform?

**Answer:**
```hcl
# Multi-region setup
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

# Primary region infrastructure
module "primary_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.primary
  }
  
  region      = "us-east-1"
  environment = "primary"
}

# DR region infrastructure
module "dr_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.dr
  }
  
  region      = "us-west-2"
  environment = "dr"
}

# Route 53 health check and failover
resource "aws_route53_health_check" "primary" {
  fqdn                            = module.primary_infrastructure.load_balancer_dns
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
}

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name                   = module.primary_infrastructure.load_balancer_dns
    zone_id                = module.primary_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dr" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "dr"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  alias {
    name                   = module.dr_infrastructure.load_balancer_dns
    zone_id                = module.dr_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}
```