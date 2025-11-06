# Terraform Conditionals - Complete Guide

## Conditional Expressions

### 1. **Ternary Operator**
```hcl
# Basic syntax: condition ? true_value : false_value
locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  monitoring    = var.environment == "prod" ? true : false
  storage_size  = var.environment == "prod" ? 100 : 20
}
```

### 2. **Nested Conditionals**
```hcl
locals {
  instance_type = var.environment == "prod" ? "t3.large" : (
    var.environment == "staging" ? "t3.medium" : "t3.micro"
  )
  
  backup_retention = var.environment == "prod" ? 30 : (
    var.environment == "staging" ? 7 : 1
  )
}
```

## Conditional Resources

### 1. **Count-based Conditionals**
```hcl
# Create resource only in production
resource "aws_cloudwatch_log_group" "app_logs" {
  count = var.environment == "prod" ? 1 : 0
  
  name              = "/aws/application/${var.app_name}"
  retention_in_days = 30
}

# Create multiple resources conditionally
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}
```

### 2. **For Each Conditionals**
```hcl
# Create resources based on condition
resource "aws_instance" "conditional" {
  for_each = var.create_instances ? var.instance_configs : {}
  
  ami           = each.value.ami
  instance_type = each.value.type
  
  tags = {
    Name = each.key
  }
}
```

## Advanced Conditional Patterns

### 1. **Multiple Conditions**
```hcl
locals {
  # AND conditions
  enable_monitoring = var.environment == "prod" && var.enable_features
  
  # OR conditions  
  use_spot_instances = var.environment == "dev" || var.cost_optimization
  
  # Complex conditions
  backup_enabled = (var.environment == "prod" || var.environment == "staging") && var.data_retention_required
}
```

### 2. **Conditional Blocks**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Conditional block
  dynamic "ebs_block_device" {
    for_each = var.attach_ebs ? [1] : []
    content {
      device_name = "/dev/sdf"
      volume_size = var.ebs_size
      volume_type = "gp3"
    }
  }
}
```

## Validation and Error Handling

### 1. **Input Validation**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 2. **Safe Operations**
```hcl
locals {
  # Safe map access
  database_config = try(var.config.database, {
    engine = "mysql"
    size   = "small"
  })
  
  # Safe type conversion
  port_number = can(tonumber(var.port)) ? tonumber(var.port) : 80
  
  # Coalesce for defaults
  region = coalesce(var.region, var.default_region, "us-west-2")
}
```

## Real-World Examples

### 1. **Environment-Specific Configuration**
```hcl
locals {
  environment_config = {
    dev = {
      instance_type     = "t3.micro"
      instance_count    = 1
      enable_monitoring = false
      backup_retention  = 1
    }
    staging = {
      instance_type     = "t3.small"
      instance_count    = 2
      enable_monitoring = true
      backup_retention  = 7
    }
    prod = {
      instance_type     = "t3.large"
      instance_count    = 5
      enable_monitoring = true
      backup_retention  = 30
    }
  }
  
  config = local.environment_config[var.environment]
}

resource "aws_instance" "web" {
  count = local.config.instance_count
  
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
  monitoring    = local.config.enable_monitoring
}
```

### 2. **Feature Flags**
```hcl
variable "features" {
  description = "Feature flags"
  type = object({
    enable_ssl        = bool
    enable_monitoring = bool
    enable_backup     = bool
  })
  default = {
    enable_ssl        = true
    enable_monitoring = false
    enable_backup     = false
  }
}

# SSL Certificate
resource "aws_acm_certificate" "main" {
  count = var.features.enable_ssl ? 1 : 0
  
  domain_name       = var.domain_name
  validation_method = "DNS"
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "app" {
  count = var.features.enable_monitoring ? 1 : 0
  
  name              = "/aws/application/${var.app_name}"
  retention_in_days = 7
}

# Backup Plan
resource "aws_backup_plan" "main" {
  count = var.features.enable_backup ? 1 : 0
  
  name = "${var.app_name}-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 5 ? * * *)"
  }
}
```

## Best Practices

### 1. **Readable Conditions**
```hcl
# Good - clear and readable
locals {
  is_production     = var.environment == "prod"
  is_high_traffic   = var.expected_users > 1000
  needs_scaling     = local.is_production && local.is_high_traffic
}

resource "aws_autoscaling_group" "web" {
  min_size = local.needs_scaling ? 3 : 1
  max_size = local.needs_scaling ? 10 : 3
}

# Bad - complex inline conditions
resource "aws_autoscaling_group" "web" {
  min_size = var.environment == "prod" && var.expected_users > 1000 ? 3 : 1
}
```

### 2. **Default Values**
```hcl
# Use coalesce for cascading defaults
locals {
  instance_type = coalesce(
    var.instance_type,
    local.environment_defaults[var.environment].instance_type,
    "t3.micro"
  )
}
```

## Conclusion

Conditionals in Terraform enable dynamic and flexible infrastructure configurations. Use them wisely to create environment-specific resources, implement feature flags, and handle different deployment scenarios while maintaining code readability and maintainability.