# Terraform State Management - Complete Guide

## What is Terraform State?

Terraform state is a file that maps your Terraform configuration to real-world resources. It tracks metadata about your infrastructure and is essential for Terraform to know what resources it manages and their current state.

## State File Structure

### Basic State File (terraform.tfstate)
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 1,
  "lineage": "12345678-1234-1234-1234-123456789012",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-12345678",
            "instance_type": "t2.micro",
            "public_ip": "203.0.113.12",
            "private_ip": "10.0.1.100"
          },
          "sensitive_attributes": [],
          "private": "eyJzY2hlbWFfdmVyc2lvbiI6IjEifQ==",
          "dependencies": [
            "aws_security_group.web"
          ]
        }
      ]
    }
  ]
}
```

### State File Components

#### 1. **Version Information**
```json
{
  "version": 4,                    // State format version
  "terraform_version": "1.6.0",   // Terraform version used
  "serial": 1,                     // State serial number
  "lineage": "uuid"                // Unique state lineage ID
}
```

#### 2. **Resources**
```json
{
  "resources": [
    {
      "mode": "managed",           // managed or data
      "type": "aws_instance",      // Resource type
      "name": "web",              // Resource name
      "provider": "provider_address",
      "instances": [              // Resource instances
        {
          "attributes": {},       // Resource attributes
          "dependencies": []      // Resource dependencies
        }
      ]
    }
  ]
}
```

## Local State vs Remote State

### 1. **Local State**
State stored locally in `terraform.tfstate` file

#### Advantages:
- Simple setup
- No additional infrastructure needed
- Fast access

#### Disadvantages:
- No collaboration support
- No locking mechanism
- Risk of data loss
- No versioning

```bash
# Local state files
terraform.tfstate          # Current state
terraform.tfstate.backup   # Previous state backup
```

### 2. **Remote State**
State stored in remote backend (S3, Consul, etc.)

#### Advantages:
- Team collaboration
- State locking
- Versioning and backup
- Security and encryption
- Audit trail

#### Disadvantages:
- Additional setup required
- Dependency on remote service
- Potential network latency

## State Operations

### 1. **Viewing State**
```bash
# Show current state
terraform show

# Show state in JSON format
terraform show -json

# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Show resource with count
terraform state show 'aws_instance.web[0]'

# Show resource with for_each
terraform state show 'aws_instance.web["production"]'
```

### 2. **State Manipulation**
```bash
# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Move resource with count
terraform state mv 'aws_instance.web[0]' 'aws_instance.web[1]'

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.web

# Replace resource address
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

### 3. **State Import**
```bash
# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Import with count
terraform import 'aws_instance.web[0]' i-1234567890abcdef0

# Import with for_each
terraform import 'aws_instance.web["production"]' i-1234567890abcdef0
```

### 4. **State Refresh**
```bash
# Refresh state to match real infrastructure
terraform refresh

# Refresh specific resource
terraform refresh -target=aws_instance.web
```

## State Locking

### What is State Locking?
State locking prevents multiple users from running Terraform simultaneously, which could corrupt the state file.

### Automatic Locking
```hcl
# S3 backend with DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"  # Enables locking
    encrypt        = true
  }
}
```

### Manual Lock Operations
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Show lock info
terraform show -json | jq '.serial'
```

### Lock Timeout
```bash
# Set lock timeout
terraform apply -lock-timeout=10m
```

## State Backends

### 1. **Local Backend (Default)**
```hcl
# No configuration needed - default behavior
# State stored in terraform.tfstate
```

### 2. **S3 Backend**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "path/to/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    
    # Optional: Server-side encryption
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    
    # Optional: Access control
    acl = "bucket-owner-full-control"
  }
}
```

### 3. **Azure Backend**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### 4. **Google Cloud Backend**
```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket"
    prefix = "terraform/state"
  }
}
```

### 5. **Consul Backend**
```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/myproject"
  }
}
```

### 6. **Terraform Cloud Backend**
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "my-workspace"
    }
  }
}
```

## State Migration

### 1. **Migrating from Local to Remote**
```bash
# Step 1: Add backend configuration
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Step 2: Initialize with migration
terraform init -migrate-state
```

### 2. **Migrating Between Backends**
```bash
# Change backend configuration and run
terraform init -migrate-state

# Force copy without prompting
terraform init -migrate-state -force-copy
```

### 3. **Reconfiguring Backend**
```bash
# Reconfigure backend settings
terraform init -reconfigure

# Upgrade backend
terraform init -upgrade
```

## State Workspaces

### What are Workspaces?
Workspaces allow you to manage multiple environments with the same configuration but separate state files.

### Workspace Commands
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new production

# Select workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging
```

### Workspace Usage
```hcl
# Use workspace name in configuration
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
  
  tags = {
    Name        = "${terraform.workspace}-web-server"
    Environment = terraform.workspace
  }
}

# Workspace-specific variables
locals {
  environment_config = {
    default = {
      instance_count = 1
      instance_type  = "t3.micro"
    }
    production = {
      instance_count = 3
      instance_type  = "t3.large"
    }
  }
  
  config = lookup(local.environment_config, terraform.workspace, local.environment_config.default)
}
```

## State Security

### 1. **Encryption at Rest**
```hcl
# S3 backend with encryption
terraform {
  backend "s3" {
    bucket     = "my-terraform-state"
    key        = "terraform.tfstate"
    region     = "us-west-2"
    encrypt    = true
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

### 2. **Access Control**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/TerraformRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::my-terraform-state/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/TerraformRole"
      },
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::my-terraform-state"
    }
  ]
}
```

### 3. **Sensitive Data in State**
```hcl
# Mark outputs as sensitive
output "database_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}

# Use external secret management
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "database-password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

## State Backup and Recovery

### 1. **Automatic Backups**
```bash
# Terraform automatically creates backups
terraform.tfstate.backup    # Previous state version
```

### 2. **Manual Backups**
```bash
# Create manual backup
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# Pull remote state for backup
terraform state pull > terraform.tfstate.backup
```

### 3. **State Recovery**
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Push state to remote backend
terraform state push terraform.tfstate
```

### 4. **S3 Versioning**
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

## State Troubleshooting

### Common Issues

#### 1. **State Lock Issues**
```bash
# Error: state locked
# Solution: Wait or force unlock
terraform force-unlock LOCK_ID
```

#### 2. **State Drift**
```bash
# Error: resource doesn't match state
# Solution: Refresh state
terraform refresh

# Or import resource
terraform import aws_instance.web i-1234567890abcdef0
```

#### 3. **Corrupted State**
```bash
# Error: state file corrupted
# Solution: Restore from backup
cp terraform.tfstate.backup terraform.tfstate
```

#### 4. **Missing Resources**
```bash
# Error: resource not found
# Solution: Remove from state or import
terraform state rm aws_instance.missing
# or
terraform import aws_instance.missing i-1234567890abcdef0
```

### Debug State Issues
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Validate state
terraform validate

# Check state consistency
terraform plan -detailed-exitcode
```

## Best Practices

### 1. **Remote State Setup**
```hcl
# Always use remote state for teams
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "projects/myproject/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 2. **State Organization**
```bash
# Organize state by environment/project
s3://terraform-state/
├── projects/
│   ├── project1/
│   │   ├── dev/terraform.tfstate
│   │   ├── staging/terraform.tfstate
│   │   └── prod/terraform.tfstate
│   └── project2/
│       ├── dev/terraform.tfstate
│       └── prod/terraform.tfstate
```

### 3. **State Security**
```hcl
# Enable encryption and versioning
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### 4. **State Locking**
```hcl
# Always enable state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}
```

### 5. **State Backup Strategy**
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
terraform state pull > "backups/terraform.tfstate.backup.$DATE"

# Keep only last 30 backups
find backups/ -name "terraform.tfstate.backup.*" -mtime +30 -delete
```

## Advanced State Management

### 1. **State Splitting**
```bash
# Split large state files
terraform state mv 'aws_instance.web[*]' 'module.web.aws_instance.web[*]'
```

### 2. **State Merging**
```bash
# Import resources from another state
terraform import aws_instance.imported i-1234567890abcdef0
```

### 3. **Cross-State References**
```hcl
# Reference outputs from another state
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "network/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.network.outputs.subnet_id
}
```

## Conclusion

Proper state management is crucial for Terraform operations. Use remote state with locking for team environments, implement proper security measures, maintain regular backups, and follow organizational patterns. Understanding state operations and troubleshooting techniques ensures reliable infrastructure management.