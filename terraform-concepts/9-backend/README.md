# Terraform Backend - Complete Guide

## What is a Terraform Backend?

A backend in Terraform determines how state is loaded and how operations like `terraform apply` are executed. Backends are responsible for storing state and providing locking mechanisms for team collaboration.

## Backend Types

### 1. **Local Backend (Default)**
Stores state locally on disk

```hcl
# No configuration needed - this is the default
# State stored in terraform.tfstate file
```

### 2. **Remote Backends**
Store state remotely for team collaboration

## Standard Backends

### 1. **S3 Backend (AWS)**

#### Basic Configuration
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
```

#### Advanced S3 Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    dynamodb_table = "terraform-locks"
    
    # Access control
    acl            = "bucket-owner-full-control"
    
    # Workspace support
    workspace_key_prefix = "workspaces"
    
    # Authentication
    profile                 = "terraform"
    shared_credentials_file = "~/.aws/credentials"
    
    # Assume role
    assume_role {
      role_arn     = "arn:aws:iam::123456789012:role/TerraformRole"
      session_name = "terraform"
    }
  }
}
```

#### S3 Backend Setup
```hcl
# Create S3 bucket for state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for locking
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

### 2. **Azure Backend (AzureRM)**

#### Basic Configuration
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

#### Advanced Azure Configuration
```hcl
terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-state-rg"
    storage_account_name  = "terraformstate"
    container_name        = "tfstate"
    key                   = "prod/terraform.tfstate"
    
    # Authentication
    subscription_id       = "12345678-1234-1234-1234-123456789012"
    tenant_id            = "12345678-1234-1234-1234-123456789012"
    client_id            = "12345678-1234-1234-1234-123456789012"
    client_secret        = "client-secret"
    
    # Or use managed identity
    use_msi              = true
    
    # Encryption
    snapshot             = true
  }
}
```

#### Azure Backend Setup
```hcl
# Resource group
resource "azurerm_resource_group" "terraform_state" {
  name     = "terraform-state-rg"
  location = "East US"
}

# Storage account
resource "azurerm_storage_account" "terraform_state" {
  name                     = "terraformstate"
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    versioning_enabled = true
  }
}

# Storage container
resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}
```

### 3. **Google Cloud Backend (GCS)**

#### Basic Configuration
```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket"
    prefix = "terraform/state"
  }
}
```

#### Advanced GCS Configuration
```hcl
terraform {
  backend "gcs" {
    bucket                      = "terraform-state-bucket"
    prefix                      = "env/prod"
    
    # Authentication
    credentials                 = "path/to/service-account.json"
    
    # Encryption
    encryption_key             = "base64-encoded-encryption-key"
    
    # Access control
    impersonate_service_account = "terraform@project.iam.gserviceaccount.com"
  }
}
```

#### GCS Backend Setup
```hcl
# Storage bucket
resource "google_storage_bucket" "terraform_state" {
  name     = "terraform-state-bucket"
  location = "US"
  
  versioning {
    enabled = true
  }
  
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state.id
  }
}

# KMS key for encryption
resource "google_kms_key_ring" "terraform_state" {
  name     = "terraform-state"
  location = "global"
}

resource "google_kms_crypto_key" "terraform_state" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_state.id
}
```

### 4. **Consul Backend**

#### Configuration
```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/myproject"
    
    # Authentication
    token    = "consul-token"
    username = "consul-user"
    password = "consul-password"
    
    # TLS
    ca_file   = "consul-ca.pem"
    cert_file = "consul-cert.pem"
    key_file  = "consul-key.pem"
    
    # Locking
    lock = true
  }
}
```

### 5. **Terraform Cloud Backend**

#### Organization and Workspace
```hcl
terraform {
  cloud {
    organization = "my-organization"
    
    workspaces {
      name = "my-workspace"
    }
  }
}
```

#### Multiple Workspaces
```hcl
terraform {
  cloud {
    organization = "my-organization"
    
    workspaces {
      tags = ["networking", "production"]
    }
  }
}
```

### 6. **HTTP Backend**

#### Configuration
```hcl
terraform {
  backend "http" {
    address        = "https://mycompany.com/terraform_state/myproject"
    lock_address   = "https://mycompany.com/terraform_state/myproject/lock"
    unlock_address = "https://mycompany.com/terraform_state/myproject/lock"
    
    # Authentication
    username = "terraform"
    password = "secret"
    
    # Or use token
    # token = "bearer-token"
  }
}
```

## Backend Initialization

### 1. **First Time Setup**
```bash
# Initialize backend
terraform init

# Initialize with backend config file
terraform init -backend-config=backend.conf
```

### 2. **Backend Configuration File**
```hcl
# backend.conf
bucket         = "my-terraform-state"
key            = "terraform.tfstate"
region         = "us-west-2"
encrypt        = true
dynamodb_table = "terraform-locks"
```

```bash
# Use configuration file
terraform init -backend-config=backend.conf
```

### 3. **Partial Configuration**
```hcl
# Partial backend configuration
terraform {
  backend "s3" {
    # bucket and key will be provided during init
    region = "us-west-2"
    encrypt = true
  }
}
```

```bash
# Provide missing configuration
terraform init \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="key=terraform.tfstate"
```

## Backend Migration

### 1. **Local to Remote**
```bash
# Step 1: Add backend configuration
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Step 2: Migrate state
terraform init -migrate-state
```

### 2. **Remote to Remote**
```bash
# Change backend configuration
terraform {
  backend "s3" {
    bucket = "new-terraform-state"  # Changed bucket
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Migrate to new backend
terraform init -migrate-state
```

### 3. **Backend Reconfiguration**
```bash
# Reconfigure backend without migration
terraform init -reconfigure

# Force copy state
terraform init -migrate-state -force-copy
```

## Backend Security

### 1. **Encryption at Rest**
```hcl
# S3 with KMS encryption
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
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/TerraformRole",
          "arn:aws:iam::123456789012:user/terraform-user"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::my-terraform-state/*"
    },
    {
      "Sid": "TerraformStateBucketAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/TerraformRole"
        ]
      },
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::my-terraform-state"
    }
  ]
}
```

### 3. **Network Security**
```hcl
# VPC endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-west-2.s3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::my-terraform-state",
          "arn:aws:s3:::my-terraform-state/*"
        ]
      }
    ]
  })
}
```

## Backend Locking

### 1. **DynamoDB Locking (S3)**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"  # Enables locking
  }
}
```

### 2. **Lock Management**
```bash
# Show lock information
terraform show -json | jq '.serial'

# Force unlock (dangerous)
terraform force-unlock LOCK_ID

# Set lock timeout
terraform apply -lock-timeout=10m
```

### 3. **Custom Lock Implementation**
```hcl
# HTTP backend with custom locking
terraform {
  backend "http" {
    address        = "https://api.example.com/terraform/state"
    lock_address   = "https://api.example.com/terraform/lock"
    unlock_address = "https://api.example.com/terraform/unlock"
  }
}
```

## Backend Best Practices

### 1. **Environment Separation**
```hcl
# Development
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "environments/dev/terraform.tfstate"
    region = "us-west-2"
  }
}

# Production
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "environments/prod/terraform.tfstate"
    region = "us-west-2"
  }
}
```

### 2. **Project Organization**
```bash
# Hierarchical state organization
s3://company-terraform-state/
├── projects/
│   ├── project-a/
│   │   ├── dev/terraform.tfstate
│   │   ├── staging/terraform.tfstate
│   │   └── prod/terraform.tfstate
│   └── project-b/
│       ├── dev/terraform.tfstate
│       └── prod/terraform.tfstate
└── shared/
    ├── networking/terraform.tfstate
    └── security/terraform.tfstate
```

### 3. **Backend Configuration Management**
```bash
# Use environment-specific backend configs
# backend-dev.conf
bucket = "company-terraform-state"
key    = "environments/dev/terraform.tfstate"
region = "us-west-2"

# backend-prod.conf
bucket = "company-terraform-state"
key    = "environments/prod/terraform.tfstate"
region = "us-west-2"

# Initialize with specific config
terraform init -backend-config=backend-dev.conf
```

### 4. **Automation and CI/CD**
```yaml
# GitHub Actions example
name: Terraform
on: [push]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Terraform Init
      run: terraform init -backend-config=backend-prod.conf
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        
    - name: Terraform Plan
      run: terraform plan
```

## Backend Troubleshooting

### Common Issues

#### 1. **Backend Not Configured**
```bash
# Error: Backend not configured
# Solution: Add backend configuration and initialize
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

terraform init
```

#### 2. **State Lock Issues**
```bash
# Error: state locked
# Check who has the lock
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"my-terraform-state/terraform.tfstate-md5"}}'

# Force unlock if necessary
terraform force-unlock LOCK_ID
```

#### 3. **Permission Issues**
```bash
# Error: Access denied
# Check IAM permissions for:
# - S3 bucket access (GetObject, PutObject, ListBucket)
# - DynamoDB table access (GetItem, PutItem, DeleteItem)
# - KMS key access (if using encryption)
```

#### 4. **Backend Migration Issues**
```bash
# Error during migration
# Solution: Use force-copy flag
terraform init -migrate-state -force-copy

# Or reconfigure without migration
terraform init -reconfigure
```

### Debug Backend Issues
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Check backend configuration
terraform init -backend=false

# Validate backend access
aws s3 ls s3://my-terraform-state/
```

## Advanced Backend Patterns

### 1. **Multi-Region Backend**
```hcl
# Primary region
terraform {
  backend "s3" {
    bucket = "terraform-state-us-west-2"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Cross-region replication for disaster recovery
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "replicate-terraform-state"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.terraform_state_replica.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

### 2. **Backend with Workspaces**
```hcl
terraform {
  backend "s3" {
    bucket           = "terraform-state"
    key              = "terraform.tfstate"
    region           = "us-west-2"
    workspace_key_prefix = "workspaces"
  }
}

# Results in paths like:
# workspaces/dev/terraform.tfstate
# workspaces/prod/terraform.tfstate
```

### 3. **Conditional Backend Configuration**
```hcl
# Use different backends based on environment
terraform {
  backend "s3" {
    bucket = var.environment == "prod" ? "prod-terraform-state" : "dev-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Conclusion

Proper backend configuration is essential for team collaboration and state management in Terraform. Choose the appropriate backend type based on your infrastructure, implement proper security measures, enable locking mechanisms, and follow organizational patterns for state file management. Regular backups and proper access controls ensure reliable and secure infrastructure management.