# Terraform Troubleshooting - Common Issues & Solutions

## State File Issues

### Issue 1: State File Corruption
**Problem:** `Error: Failed to load state: state snapshot was created by Terraform v1.x.x, which is newer than current v1.x.x`

**Solution:**
```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. Try to recover from backup
cp terraform.tfstate.backup terraform.tfstate

# 3. If backup is corrupted, recreate state
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_security_group.web sg-1234567890abcdef0

# 4. Validate state
terraform plan
```

### Issue 2: State Lock Issues
**Problem:** `Error: Error acquiring the state lock`

**Solution:**
```bash
# Check who has the lock
terraform force-unlock LOCK_ID

# If using S3 backend, check DynamoDB table
aws dynamodb scan --table-name terraform-state-lock

# Remove stuck lock (use carefully)
aws dynamodb delete-item --table-name terraform-state-lock --key '{"LockID":{"S":"terraform-state-lock"}}'
```

### Issue 3: Resource Drift
**Problem:** Resources modified outside Terraform

**Solution:**
```bash
# 1. Detect drift
terraform plan -refresh-only

# 2. Update state to match reality
terraform apply -refresh-only

# 3. Or revert changes to match configuration
terraform apply

# 4. For specific resources
terraform refresh
terraform import aws_instance.web i-1234567890abcdef0
```

## Provider Issues

### Issue 4: Provider Version Conflicts
**Problem:** `Error: Incompatible provider version`

**Solution:**
```hcl
# terraform.tf - Lock provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

```bash
# Update providers
terraform init -upgrade

# Downgrade if needed
terraform init -upgrade=false
```

### Issue 5: Authentication Issues
**Problem:** `Error: NoCredentialsError: Unable to locate credentials`

**Solution:**
```bash
# Method 1: AWS CLI
aws configure
export AWS_PROFILE=myprofile

# Method 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Method 3: IAM roles (EC2/ECS)
# Attach IAM role to instance

# Method 4: Provider configuration
```

```hcl
provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

## Resource Dependencies

### Issue 6: Circular Dependencies
**Problem:** `Error: Cycle: aws_security_group.web, aws_security_group.db`

**Solution:**
```hcl
# Bad - Circular reference
resource "aws_security_group" "web" {
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.db.id]  # References db
  }
}

resource "aws_security_group" "db" {
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]  # References web
  }
}

# Good - Use security group rules
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

### Issue 7: Dependency Ordering
**Problem:** Resources created in wrong order

**Solution:**
```hcl
# Explicit dependencies
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public
  ]
}

# Implicit dependencies (preferred)
resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

## Configuration Issues

### Issue 8: Variable Validation Errors
**Problem:** `Error: Invalid value for variable`

**Solution:**
```hcl
# Add validation rules
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t3 type."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Issue 9: Module Path Issues
**Problem:** `Error: Module not found`

**Solution:**
```hcl
# Local modules - use relative paths
module "vpc" {
  source = "./modules/vpc"
  # ...
}

# Git modules - specify version
module "vpc" {
  source = "git::https://github.com/user/terraform-modules.git//vpc?ref=v1.0.0"
  # ...
}

# Registry modules - specify version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  # ...
}
```

## Performance Issues

### Issue 10: Slow Terraform Operations
**Problem:** Terraform operations taking too long

**Solution:**
```bash
# Enable parallelism
terraform apply -parallelism=20

# Use refresh=false for known good state
terraform plan -refresh=false

# Target specific resources
terraform apply -target=aws_instance.web

# Use partial configuration
terraform init -backend-config="bucket=my-bucket"
```

### Issue 11: Large State Files
**Problem:** State file too large, operations slow

**Solution:**
```bash
# Split into multiple state files
terraform state mv aws_instance.web ../web-tier/
terraform state mv aws_rds_instance.db ../data-tier/

# Use workspaces for environments
terraform workspace new production
terraform workspace new staging

# Use remote state data sources
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Debugging Techniques

### Issue 12: Enable Debug Logging
```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Provider-specific logging
export TF_LOG_PROVIDER=DEBUG

# Run operation
terraform apply

# Analyze logs
grep -i error terraform.log
grep -i "http request" terraform.log
```

### Issue 13: Validate Configuration
```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -check -recursive

# Check for security issues
tfsec .

# Static analysis
terraform plan -out=tfplan
terraform show -json tfplan | jq '.'
```

### Issue 14: Test Infrastructure
```bash
# Use terraform console for testing
terraform console

# Test expressions
> local.environment_config[terraform.workspace]
> length(var.availability_zones)
> cidrsubnet("10.0.0.0/16", 8, 1)

# Validate with checkov
checkov -f main.tf

# Test with terratest (Go)
go test -v -timeout 30m
```