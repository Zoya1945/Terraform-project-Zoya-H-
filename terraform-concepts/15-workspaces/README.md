# Terraform Workspaces - Complete Guide

## What are Workspaces?

Terraform workspaces allow you to manage multiple environments (dev, staging, prod) with the same configuration but separate state files. Each workspace has its own state, allowing you to deploy the same infrastructure to different environments.

## Workspace Commands

### 1. **Basic Workspace Operations**
```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Switch to workspace
terraform workspace select development

# Delete workspace (must not be current workspace)
terraform workspace delete staging
```

### 2. **Workspace with Backend**
```bash
# Initialize with backend
terraform init

# Create workspace (creates separate state file)
terraform workspace new prod

# State files are stored separately:
# s3://bucket/terraform.tfstate (default workspace)
# s3://bucket/env:/prod/terraform.tfstate (prod workspace)
```

## Using Workspaces in Configuration

### 1. **Workspace-Aware Resources**
```hcl
# Access current workspace name
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
  
  tags = {
    Name        = "${terraform.workspace}-web-server"
    Environment = terraform.workspace
  }
}

# Workspace-specific configuration
locals {
  environment_config = {
    dev = {
      instance_count = 1
      instance_type  = "t3.micro"
      db_instance    = "db.t3.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
      db_instance    = "db.t3.small"
    }
    prod = {
      instance_count = 5
      instance_type  = "t3.large"
      db_instance    = "db.t3.large"
    }
  }
  
  config = local.environment_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count = local.config.instance_count
  
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
  
  tags = {
    Name = "${terraform.workspace}-web-${count.index + 1}"
  }
}
```

### 2. **Workspace-Specific Variables**
```hcl
# variables.tf
variable "instance_configs" {
  description = "Instance configurations by workspace"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
  }))
  default = {
    default = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 2
    }
    dev = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 2
    }
    staging = {
      instance_type = "t3.small"
      min_size      = 2
      max_size      = 4
    }
    prod = {
      instance_type = "t3.large"
      min_size      = 3
      max_size      = 10
    }
  }
}

# main.tf
locals {
  # Get config for current workspace, fallback to default
  workspace_config = lookup(var.instance_configs, terraform.workspace, var.instance_configs.default)
}

resource "aws_autoscaling_group" "web" {
  name = "${terraform.workspace}-web-asg"
  
  min_size         = local.workspace_config.min_size
  max_size         = local.workspace_config.max_size
  desired_capacity = local.workspace_config.min_size
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}
```

## Advanced Workspace Patterns

### 1. **Environment-Specific Resources**
```hcl
# Create monitoring only in production
resource "aws_cloudwatch_dashboard" "main" {
  count = terraform.workspace == "prod" ? 1 : 0
  
  dashboard_name = "${terraform.workspace}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        properties = {
          metrics = [["AWS/EC2", "CPUUtilization"]]
          region  = "us-west-2"
          title   = "EC2 CPU Utilization"
        }
      }
    ]
  })
}

# Different backup retention by environment
resource "aws_db_instance" "main" {
  identifier = "${terraform.workspace}-database"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  backup_retention_period = terraform.workspace == "prod" ? 30 : (
    terraform.workspace == "staging" ? 7 : 1
  )
  
  backup_window = terraform.workspace == "prod" ? "03:00-04:00" : "05:00-06:00"
}
```

### 2. **Workspace-Specific Networking**
```hcl
# Different CIDR blocks per workspace
locals {
  vpc_cidrs = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }
  
  vpc_cidr = lookup(local.vpc_cidrs, terraform.workspace, "10.99.0.0/16")
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${terraform.workspace}-vpc"
    Environment = terraform.workspace
  }
}

# Environment-specific subnets
resource "aws_subnet" "public" {
  count = terraform.workspace == "prod" ? 3 : 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${terraform.workspace}-public-${count.index + 1}"
  }
}
```

### 3. **Workspace-Specific Providers**
```hcl
# Different regions per workspace
locals {
  workspace_regions = {
    dev     = "us-west-2"
    staging = "us-west-2"
    prod    = "us-east-1"
  }
  
  region = lookup(local.workspace_regions, terraform.workspace, "us-west-2")
}

provider "aws" {
  region = local.region
  
  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "terraform"
      Region      = local.region
    }
  }
}

# Workspace-specific backend configuration
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
    
    # Workspace key prefix creates separate state files
    workspace_key_prefix = "workspaces"
  }
}
```

## Workspace Variable Files

### 1. **Environment-Specific tfvars**
```hcl
# dev.tfvars
environment     = "dev"
instance_type   = "t3.micro"
instance_count  = 1
enable_monitoring = false

# staging.tfvars
environment     = "staging"
instance_type   = "t3.small"
instance_count  = 2
enable_monitoring = true

# prod.tfvars
environment     = "prod"
instance_type   = "t3.large"
instance_count  = 5
enable_monitoring = true
```

```bash
# Use with workspaces
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

### 2. **Automatic Variable Loading**
```hcl
# terraform.tfvars (loaded automatically)
# Common variables for all workspaces
project_name = "my-app"
owner        = "devops-team"

# dev.auto.tfvars (loaded automatically in dev workspace)
instance_type = "t3.micro"

# prod.auto.tfvars (loaded automatically in prod workspace)
instance_type = "t3.large"
```

## Workspace Best Practices

### 1. **Workspace Validation**
```hcl
# Validate workspace names
locals {
  valid_workspaces = ["dev", "staging", "prod"]
}

# Check if current workspace is valid
resource "null_resource" "workspace_validation" {
  count = contains(local.valid_workspaces, terraform.workspace) ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'Invalid workspace: ${terraform.workspace}. Valid workspaces: ${join(\", \", local.valid_workspaces)}' && exit 1"
  }
}
```

### 2. **Workspace-Aware Naming**
```hcl
locals {
  # Consistent naming convention
  name_prefix = "${var.project_name}-${terraform.workspace}"
  
  # Resource names
  vpc_name    = "${local.name_prefix}-vpc"
  sg_name     = "${local.name_prefix}-sg"
  db_name     = "${local.name_prefix}-db"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = local.vpc_name
  }
}
```

### 3. **Environment Isolation**
```hcl
# Separate S3 buckets per workspace
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${terraform.workspace}-data"
  
  tags = {
    Environment = terraform.workspace
  }
}

# Environment-specific KMS keys
resource "aws_kms_key" "main" {
  description = "KMS key for ${terraform.workspace} environment"
  
  tags = {
    Name        = "${terraform.workspace}-kms-key"
    Environment = terraform.workspace
  }
}
```

## Workspace Automation

### 1. **CI/CD Integration**
```yaml
# GitHub Actions example
name: Terraform Deploy
on:
  push:
    branches: [main, develop]

jobs:
  terraform:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        workspace: [dev, staging, prod]
        
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Terraform Init
      run: terraform init
      
    - name: Select Workspace
      run: |
        terraform workspace select ${{ matrix.workspace }} || \
        terraform workspace new ${{ matrix.workspace }}
        
    - name: Terraform Plan
      run: terraform plan -var-file="${{ matrix.workspace }}.tfvars"
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve -var-file="${{ matrix.workspace }}.tfvars"
```

### 2. **Makefile for Workspace Management**
```makefile
# Makefile
.PHONY: init plan apply destroy

WORKSPACE ?= dev
VAR_FILE = $(WORKSPACE).tfvars

init:
	terraform init
	terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)

plan: init
	terraform plan -var-file=$(VAR_FILE)

apply: init
	terraform apply -var-file=$(VAR_FILE)

destroy: init
	terraform destroy -var-file=$(VAR_FILE)

# Usage:
# make plan WORKSPACE=dev
# make apply WORKSPACE=prod
```

## Workspace Limitations

### 1. **State File Isolation**
```bash
# Workspaces share the same backend configuration
# Cannot have different backends per workspace
# All workspaces must use the same provider versions
```

### 2. **Alternative: Directory Structure**
```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars

# Each environment has its own:
# - Backend configuration
# - Provider versions
# - Variable files
# - State files
```

## Workspace Migration

### 1. **Moving from Workspaces to Directories**
```bash
# Export state from workspace
terraform workspace select prod
terraform state pull > prod-state.json

# Create new directory structure
mkdir -p environments/prod
cd environments/prod

# Initialize new backend
terraform init

# Import state
terraform state push prod-state.json
```

### 2. **Workspace Cleanup**
```bash
# List all workspaces
terraform workspace list

# Delete unused workspaces
terraform workspace select default
terraform workspace delete old-workspace

# Clean up remote state files if needed
aws s3 rm s3://bucket/env:/old-workspace/ --recursive
```

## Troubleshooting Workspaces

### Common Issues

#### 1. **Workspace Not Found**
```bash
# Error: workspace doesn't exist
# Solution: Create workspace first
terraform workspace new missing-workspace
```

#### 2. **State File Conflicts**
```bash
# Error: state locked
# Solution: Check workspace and unlock if needed
terraform workspace show
terraform force-unlock LOCK_ID
```

#### 3. **Resource Naming Conflicts**
```bash
# Error: resource already exists
# Solution: Use workspace-aware naming
resource "aws_s3_bucket" "data" {
  bucket = "${var.project}-${terraform.workspace}-data"
}
```

### Debug Workspaces
```bash
# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Show state file location
terraform show -json | jq '.values.root_module'

# Verify backend configuration
terraform init -backend=false
```

## Best Practices Summary

### 1. **When to Use Workspaces**
- ✅ Same infrastructure, different environments
- ✅ Simple environment separation
- ✅ Shared backend configuration
- ❌ Different provider versions per environment
- ❌ Complex environment-specific configurations

### 2. **Workspace Naming**
```hcl
# Use consistent, descriptive names
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# Avoid generic names
# terraform workspace new env1  # Bad
# terraform workspace new test  # Bad
```

### 3. **Resource Naming**
```hcl
# Always include workspace in resource names
resource "aws_instance" "web" {
  tags = {
    Name = "${terraform.workspace}-web-server"
  }
}

# Use locals for consistent naming
locals {
  name_prefix = "${var.project}-${terraform.workspace}"
}
```

## Conclusion

Terraform workspaces provide a simple way to manage multiple environments with the same configuration. They're ideal for scenarios where you need environment separation but want to maintain a single codebase. For more complex scenarios with different provider configurations or significantly different infrastructure per environment, consider using separate directories or modules instead.