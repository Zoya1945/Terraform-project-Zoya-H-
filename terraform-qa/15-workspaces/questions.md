# Terraform Workspaces - Q&A

## Basic Questions

### Q1: What are Terraform workspaces?
**Answer:** Terraform workspaces allow you to manage multiple environments (dev, staging, prod) with the same configuration but separate state files. Each workspace maintains its own state, enabling you to deploy identical infrastructure to different environments.

### Q2: What is the default workspace in Terraform?
**Answer:** The default workspace is called "default". When you initialize a new Terraform configuration, you're automatically in the default workspace.

### Q3: How do you create a new workspace?
**Answer:**
```bash
terraform workspace new development
terraform workspace new staging
terraform workspace new production
```

### Q4: How do you list all available workspaces?
**Answer:**
```bash
terraform workspace list
```
The current workspace is marked with an asterisk (*).

### Q5: How do you switch between workspaces?
**Answer:**
```bash
terraform workspace select development
terraform workspace select production
```

## Intermediate Questions

### Q6: How do you access the current workspace name in Terraform configuration?
**Answer:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name        = "${terraform.workspace}-web-server"
    Environment = terraform.workspace
  }
}
```

### Q7: How do workspaces affect state file storage?
**Answer:**
- **Local Backend**: Creates separate directories: `terraform.tfstate.d/workspace_name/`
- **Remote Backend**: Uses workspace key prefix: `env:/workspace_name/terraform.tfstate`
- **S3 Backend**: Stores as separate objects with workspace prefix

### Q8: How do you create workspace-specific configurations?
**Answer:**
```hcl
locals {
  environment_config = {
    dev = {
      instance_count = 1
      instance_type  = "t3.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.small"
    }
    prod = {
      instance_count = 5
      instance_type  = "t3.large"
    }
  }
  
  config = local.environment_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count = local.config.instance_count
  
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
}
```

### Q9: How do you delete a workspace?
**Answer:**
```bash
# Switch to another workspace first
terraform workspace select default

# Then delete the workspace
terraform workspace delete staging
```
Note: You cannot delete the workspace you're currently in.

### Q10: What happens when you run terraform plan/apply in different workspaces?
**Answer:** Each workspace maintains its own state file, so:
- `terraform plan` shows changes specific to that workspace's state
- `terraform apply` only affects resources in the current workspace
- Resources in different workspaces are completely isolated

## Advanced Questions

### Q11: How do you implement workspace validation?
**Answer:**
```hcl
locals {
  valid_workspaces = ["dev", "staging", "prod"]
}

resource "null_resource" "workspace_validation" {
  count = contains(local.valid_workspaces, terraform.workspace) ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'Invalid workspace: ${terraform.workspace}' && exit 1"
  }
}
```

### Q12: How do you handle workspace-specific variable files?
**Answer:**
```bash
# Method 1: Manual specification
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# Method 2: Automatic loading with naming convention
# dev.auto.tfvars (loaded automatically in dev workspace)
# prod.auto.tfvars (loaded automatically in prod workspace)
```

### Q13: What are the limitations of Terraform workspaces?
**Answer:**
- **Limited Isolation**: Same backend, potential for conflicts
- **State File Management**: Can become complex with many workspaces
- **No Built-in Access Control**: All workspaces accessible to same user
- **Backend Limitations**: Some backends don't support workspaces well
- **Debugging Complexity**: Harder to troubleshoot across workspaces

### Q14: How do you implement workspace-specific networking?
**Answer:**
```hcl
locals {
  vpc_cidrs = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }
  
  vpc_cidr = lookup(local.vpc_cidrs, terraform.workspace, "10.99.0.0/16")
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr
  
  tags = {
    Name        = "${terraform.workspace}-vpc"
    Environment = terraform.workspace
  }
}
```

### Q15: How do you handle workspace-specific providers?
**Answer:**
```hcl
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
    }
  }
}
```

### Q16: What are alternatives to Terraform workspaces?
**Answer:**
- **Separate Directories**: Different folders for each environment
- **Terragrunt**: Tool for managing multiple Terraform configurations
- **Terraform Cloud/Enterprise**: Built-in workspace management
- **Git Branches**: Environment-specific branches
- **Multiple State Files**: Manual state file management

### Q17: How do you implement workspace-based conditional resources?
**Answer:**
```hcl
# Create monitoring only in production
resource "aws_cloudwatch_dashboard" "main" {
  count = terraform.workspace == "prod" ? 1 : 0
  
  dashboard_name = "${terraform.workspace}-dashboard"
  # ... dashboard configuration
}

# Different backup retention by environment
resource "aws_db_instance" "main" {
  identifier = "${terraform.workspace}-database"
  
  backup_retention_period = terraform.workspace == "prod" ? 30 : (
    terraform.workspace == "staging" ? 7 : 1
  )
}
```

### Q18: How do you manage workspace state in CI/CD?
**Answer:**
```yaml
# GitHub Actions example
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