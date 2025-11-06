# Terraform Variables - Complete Guide

## What are Variables?

Variables in Terraform allow you to parameterize your configurations, making them flexible and reusable across different environments. There are three types of variables: input variables, local values, and output values.

## Input Variables

### Basic Syntax
```hcl
variable "variable_name" {
  description = "Description of the variable"
  type        = variable_type
  default     = default_value
  sensitive   = true/false
  nullable    = true/false
  
  validation {
    condition     = validation_condition
    error_message = "Error message"
  }
}
```

### Variable Types

#### 1. **String Variables**
```hcl
variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "web-server"
}

variable "environment" {
  description = "Environment name"
  type        = string
  # No default - must be provided
}

# Multi-line string
variable "user_data" {
  description = "User data script"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
  EOF
}
```

#### 2. **Number Variables**
```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port number"
  type        = number
  default     = 80
}

variable "cpu_credits" {
  description = "CPU credits for t2/t3 instances"
  type        = number
  default     = 0.5
}
```

#### 3. **Boolean Variables**
```hcl
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "public_access" {
  description = "Allow public access"
  type        = bool
  default     = true
}
```

#### 4. **List Variables**
```hcl
# List of strings
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# List of numbers
variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  default     = [80, 443, 22]
}

# List of objects
variable "instances" {
  description = "List of instance configurations"
  type = list(object({
    name = string
    type = string
    size = number
  }))
  default = [
    {
      name = "web"
      type = "t3.micro"
      size = 20
    },
    {
      name = "app"
      type = "t3.small"
      size = 30
    }
  ]
}
```

#### 5. **Map Variables**
```hcl
# Map of strings
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "production"
    Team        = "devops"
    Project     = "web-app"
  }
}

# Map of numbers
variable "instance_sizes" {
  description = "Instance disk sizes by type"
  type        = map(number)
  default = {
    web = 20
    app = 50
    db  = 100
  }
}

# Map of objects
variable "environments" {
  description = "Environment configurations"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
  }))
  default = {
    dev = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 2
    }
    prod = {
      instance_type = "t3.large"
      min_size      = 3
      max_size      = 10
    }
  }
}
```

#### 6. **Object Variables**
```hcl
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    allocated_storage = number
    multi_az       = bool
    backup_retention = number
    tags           = map(string)
  })
  default = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    multi_az          = false
    backup_retention  = 7
    tags = {
      Environment = "dev"
    }
  }
}
```

#### 7. **Tuple Variables**
```hcl
variable "server_config" {
  description = "Server configuration tuple"
  type        = tuple([string, number, bool])
  default     = ["web-server", 80, true]
}
```

#### 8. **Set Variables**
```hcl
variable "security_groups" {
  description = "Set of security group IDs"
  type        = set(string)
  default     = ["sg-12345", "sg-67890"]
}
```

### Variable Validation

#### 1. **Basic Validation**
```hcl
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
```

#### 2. **Regex Validation**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}
```

#### 3. **Complex Validation**
```hcl
variable "port_range" {
  description = "Port range configuration"
  type = object({
    from_port = number
    to_port   = number
  })
  
  validation {
    condition = (
      var.port_range.from_port >= 1 &&
      var.port_range.from_port <= 65535 &&
      var.port_range.to_port >= 1 &&
      var.port_range.to_port <= 65535 &&
      var.port_range.from_port <= var.port_range.to_port
    )
    error_message = "Port range must be valid (1-65535) and from_port <= to_port."
  }
}
```

### Variable Sensitivity
```hcl
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  # No default for sensitive values
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
}
```

### Variable Nullability
```hcl
variable "optional_tag" {
  description = "Optional tag value"
  type        = string
  default     = null
  nullable    = true
}

variable "required_value" {
  description = "Required value that cannot be null"
  type        = string
  nullable    = false
}
```

## Local Values

### Basic Local Values
```hcl
locals {
  # Simple values
  environment = "production"
  region      = "us-west-2"
  
  # Computed values
  instance_name = "${var.project_name}-${var.environment}-web"
  
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  }
  
  # Conditional values
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  
  # Complex computations
  subnet_cidrs = [
    for i in range(length(var.availability_zones)) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
}
```

### Advanced Local Values
```hcl
locals {
  # Map transformations
  instance_configs = {
    for env, config in var.environments :
    env => {
      instance_type = config.instance_type
      min_size      = config.min_size
      max_size      = config.max_size
      tags = merge(local.common_tags, {
        Environment = env
      })
    }
  }
  
  # List transformations
  security_group_rules = flatten([
    for port in var.allowed_ports : [
      {
        from_port   = port
        to_port     = port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  ])
  
  # Conditional lists
  monitoring_enabled = var.environment == "prod" ? [1] : []
}
```

## Output Values

### Basic Outputs
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.web.public_ip
  sensitive   = false
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

### Complex Outputs
```hcl
output "instance_details" {
  description = "Complete instance information"
  value = {
    id         = aws_instance.web.id
    public_ip  = aws_instance.web.public_ip
    private_ip = aws_instance.web.private_ip
    dns_name   = aws_instance.web.public_dns
  }
}

output "all_instance_ips" {
  description = "All instance IP addresses"
  value = {
    for instance in aws_instance.web :
    instance.tags.Name => {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}
```

## Variable Assignment

### 1. **Command Line**
```bash
# Single variable
terraform apply -var="instance_type=t3.small"

# Multiple variables
terraform apply -var="instance_type=t3.small" -var="environment=prod"
```

### 2. **Variable Files**
```hcl
# terraform.tfvars (automatically loaded)
instance_type = "t3.small"
environment   = "production"
region        = "us-west-2"

tags = {
  Team    = "DevOps"
  Project = "WebApp"
}

# prod.tfvars (manually specified)
instance_type = "t3.large"
environment   = "prod"
instance_count = 5
```

```bash
# Use specific variable file
terraform apply -var-file="prod.tfvars"
```

### 3. **Environment Variables**
```bash
# Set environment variables
export TF_VAR_instance_type="t3.small"
export TF_VAR_environment="production"
export TF_VAR_instance_count=3

# Run terraform
terraform apply
```

### 4. **Auto-loaded Files**
Terraform automatically loads:
- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

```hcl
# dev.auto.tfvars
environment    = "dev"
instance_type  = "t3.micro"
instance_count = 1

# prod.auto.tfvars
environment    = "prod"
instance_type  = "t3.large"
instance_count = 5
```

## Variable Precedence

Terraform loads variables in this order (later sources override earlier ones):

1. Environment variables (`TF_VAR_name`)
2. `terraform.tfvars` file
3. `terraform.tfvars.json` file
4. `*.auto.tfvars` files (alphabetical order)
5. `*.auto.tfvars.json` files (alphabetical order)
6. Command line `-var` and `-var-file` options

## Advanced Variable Patterns

### 1. **Environment-Specific Variables**
```hcl
# variables.tf
variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    instance_type  = string
    instance_count = number
    monitoring     = bool
  }))
  default = {
    dev = {
      instance_type  = "t3.micro"
      instance_count = 1
      monitoring     = false
    }
    staging = {
      instance_type  = "t3.small"
      instance_count = 2
      monitoring     = true
    }
    prod = {
      instance_type  = "t3.large"
      instance_count = 5
      monitoring     = true
    }
  }
}

# main.tf
locals {
  config = var.environment_configs[var.environment]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
  monitoring    = local.config.monitoring
}
```

### 2. **Feature Flags**
```hcl
variable "features" {
  description = "Feature flags"
  type = object({
    enable_monitoring = bool
    enable_backup     = bool
    enable_encryption = bool
  })
  default = {
    enable_monitoring = true
    enable_backup     = true
    enable_encryption = true
  }
}

# Conditional resources based on feature flags
resource "aws_cloudwatch_log_group" "app" {
  count = var.features.enable_monitoring ? 1 : 0
  name  = "/aws/application/myapp"
}

resource "aws_backup_plan" "main" {
  count = var.features.enable_backup ? 1 : 0
  name  = "backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * * *)"
  }
}
```

### 3. **Dynamic Configuration**
```hcl
variable "security_rules" {
  description = "Dynamic security group rules"
  type = list(object({
    name        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      name        = "http"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      name        = "https"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  dynamic "ingress" {
    for_each = var.security_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

## Best Practices

### 1. **Variable Organization**
```hcl
# Group related variables
# networking.tf
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

# compute.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}
```

### 2. **Variable Documentation**
```hcl
variable "database_config" {
  description = <<-EOT
    Database configuration object containing:
    - engine: Database engine (mysql, postgres)
    - version: Engine version
    - instance_class: RDS instance class
    - storage: Allocated storage in GB
    - multi_az: Enable Multi-AZ deployment
  EOT
  
  type = object({
    engine         = string
    version        = string
    instance_class = string
    storage        = number
    multi_az       = bool
  })
  
  default = {
    engine         = "mysql"
    version        = "8.0"
    instance_class = "db.t3.micro"
    storage        = 20
    multi_az       = false
  }
}
```

### 3. **Variable Validation**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains([
      "dev", "staging", "prod"
    ], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

### 4. **Sensitive Data Handling**
```hcl
# Mark sensitive variables
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Use random passwords
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}
```

## Troubleshooting Variables

### Common Issues

#### 1. **Variable Not Found**
```bash
# Error: Variable not declared
# Solution: Declare variable in variables.tf
variable "missing_variable" {
  description = "Previously missing variable"
  type        = string
}
```

#### 2. **Type Mismatch**
```bash
# Error: Invalid value for variable
# Solution: Check variable type and provided value
variable "port" {
  type = number  # Ensure this matches the provided value
}
```

#### 3. **Validation Failure**
```bash
# Error: Invalid value for variable
# Solution: Check validation rules and fix input
variable "environment" {
  validation {
    condition = contains(["dev", "prod"], var.environment)
    error_message = "Must be dev or prod."
  }
}
```

### Debug Variables
```bash
# Show variable values
terraform console
> var.instance_type
> local.common_tags

# Validate configuration
terraform validate

# Plan with variable details
terraform plan -var="debug=true"
```

## Conclusion

Variables are essential for creating flexible and reusable Terraform configurations. Understanding input variables, local values, output values, and their various types and features enables you to build dynamic and maintainable infrastructure code. Always use appropriate validation, follow naming conventions, and handle sensitive data properly.