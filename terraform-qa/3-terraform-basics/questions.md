# Terraform Basics - Q&A

## Basic Questions

### Q1: What is Terraform?
**Answer:** Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp that allows you to define and provision infrastructure using declarative configuration files.

### Q2: What are the main Terraform commands?
**Answer:**
- `terraform init` - Initialize working directory
- `terraform plan` - Create execution plan
- `terraform apply` - Apply changes
- `terraform destroy` - Destroy infrastructure
- `terraform validate` - Validate configuration
- `terraform fmt` - Format configuration files

### Q3: What is the Terraform workflow?
**Answer:**
1. **Write** - Author infrastructure as code
2. **Plan** - Preview changes before applying
3. **Apply** - Provision reproducible infrastructure

### Q4: What file extensions does Terraform use?
**Answer:**
- `.tf` - Terraform configuration files
- `.tfvars` - Variable definition files
- `.tfstate` - State files
- `.tfstate.backup` - State backup files

### Q5: What is terraform init and when do you use it?
**Answer:** `terraform init` initializes a Terraform working directory. Use it:
- When starting a new Terraform project
- After adding new providers
- After changing backend configuration
- When cloning a repository with Terraform code

## Intermediate Questions

### Q6: What is the difference between terraform plan and terraform apply?
**Answer:**
- **terraform plan**: Creates an execution plan showing what actions Terraform will take without making changes
- **terraform apply**: Executes the actions proposed in a plan to reach the desired state

### Q7: How do you target specific resources during apply/destroy?
**Answer:**
```bash
# Target specific resource
terraform apply -target=aws_instance.web

# Target multiple resources
terraform apply -target=aws_instance.web -target=aws_security_group.web

# Destroy specific resource
terraform destroy -target=aws_instance.web
```

### Q8: What is terraform validate and why is it important?
**Answer:** `terraform validate` checks the syntax and internal consistency of Terraform configuration files. It's important because:
- Catches syntax errors early
- Validates resource configurations
- Checks for required arguments
- Runs quickly without accessing remote services

### Q9: How do you format Terraform code?
**Answer:**
```bash
# Format files in current directory
terraform fmt

# Format files recursively
terraform fmt -recursive

# Check if files are formatted (CI/CD)
terraform fmt -check
```

### Q10: What is the purpose of terraform refresh?
**Answer:** `terraform refresh` updates the state file with the real-world infrastructure. It:
- Reads current settings from remote objects
- Updates state file to match reality
- Doesn't modify infrastructure
- Helps detect configuration drift

## Advanced Questions

### Q11: How do you handle Terraform state file corruption?
**Answer:**
```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. Try to recover from backup
cp terraform.tfstate.backup terraform.tfstate

# 3. If backup is also corrupted, reimport resources
terraform import aws_instance.web i-1234567890abcdef0

# 4. Validate state
terraform plan
```

### Q12: What are Terraform provisioners and when should you use them?
**Answer:** Provisioners execute scripts on local/remote machines as part of resource creation/destruction. Use them:
- **Sparingly** - Terraform prefers declarative approach
- For bootstrapping
- When provider doesn't support required functionality
- As last resort

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd"
    ]
  }
}
```

### Q13: How do you handle sensitive data in Terraform?
**Answer:**
```hcl
# Mark variables as sensitive
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Use sensitive outputs
output "db_password" {
  value     = var.db_password
  sensitive = true
}

# Store in external systems
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}
```

### Q14: What is terraform graph and how is it useful?
**Answer:** `terraform graph` generates a visual representation of the dependency graph:
```bash
# Generate graph
terraform graph | dot -Tsvg > graph.svg

# View dependencies
terraform graph | grep -E "(aws_instance|aws_security_group)"
```
Useful for:
- Understanding resource dependencies
- Debugging complex configurations
- Documentation purposes

### Q15: How do you debug Terraform issues?
**Answer:**
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Different log levels
export TF_LOG=TRACE  # Most verbose
export TF_LOG=DEBUG
export TF_LOG=INFO
export TF_LOG=WARN
export TF_LOG=ERROR

# Provider-specific logging
export TF_LOG_PROVIDER=DEBUG

# Run with debugging
terraform apply
```

### Q16: What are Terraform data sources?
**Answer:** Data sources allow Terraform to fetch information from external systems:
```hcl
# Fetch existing VPC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Use in resource
resource "aws_subnet" "web" {
  vpc_id = data.aws_vpc.existing.id
  # ...
}
```

### Q17: How do you handle Terraform version constraints?
**Answer:**
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

### Q18: What is the difference between count and for_each?
**Answer:**
- **count**: Creates multiple instances using numeric index
- **for_each**: Creates instances using map/set keys

```hcl
# Using count
resource "aws_instance" "web" {
  count = 3
  # Access with count.index
}

# Using for_each
resource "aws_instance" "web" {
  for_each = toset(["web1", "web2", "web3"])
  # Access with each.key and each.value
}
```