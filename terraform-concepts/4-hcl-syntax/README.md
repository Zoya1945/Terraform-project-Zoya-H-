# HCL Syntax - Complete Guide

## What is HCL?

HCL (HashiCorp Configuration Language) is a structured configuration language designed to be both human and machine-readable. It's used by Terraform and other HashiCorp tools.

## Basic Syntax Elements

### 1. **Blocks**
```hcl
# Basic block structure
block_type "block_label" "block_label" {
  # Block body
  argument = value
}

# Examples
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### 2. **Arguments**
```hcl
# String arguments
name = "web-server"
description = "Web server instance"

# Number arguments
count = 3
port = 80

# Boolean arguments
enabled = true
monitoring = false

# List arguments
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
security_groups = [
  "sg-12345678",
  "sg-87654321"
]

# Map arguments
tags = {
  Name        = "WebServer"
  Environment = "Production"
  Owner       = "DevOps"
}

# Object arguments
ingress_rule = {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### 3. **Comments**
```hcl
# Single line comment

/*
Multi-line comment
can span multiple lines
*/

resource "aws_instance" "web" {
  ami           = "ami-12345678"  # Inline comment
  instance_type = "t2.micro"     // Alternative inline comment
}
```

## Data Types

### 1. **Primitive Types**

#### String
```hcl
# Simple string
name = "web-server"

# Multi-line string
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
EOF

# Heredoc with indentation
script = <<EOF
#!/bin/bash
echo "Hello World"
EOF
```

#### Number
```hcl
# Integer
count = 3
port = 80

# Float
cpu_credits = 0.5
memory_ratio = 1.5
```

#### Boolean
```hcl
enabled = true
monitoring = false
```

### 2. **Collection Types**

#### List
```hcl
# List of strings
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# List of numbers
ports = [80, 443, 22]

# Mixed types (not recommended)
mixed_list = ["string", 123, true]
```

#### Map
```hcl
# Map of strings
tags = {
  Name        = "WebServer"
  Environment = "Production"
  Owner       = "DevOps"
}

# Map with different value types
instance_config = {
  type         = "t2.micro"
  count        = 2
  monitoring   = true
}
```

#### Set
```hcl
# Set (similar to list but unique values)
security_group_ids = toset([
  "sg-12345678",
  "sg-87654321"
])
```

### 3. **Structural Types**

#### Object
```hcl
# Object type
server_config = {
  name         = "web-server"
  instance_type = "t2.micro"
  ports        = [80, 443]
  tags = {
    Environment = "prod"
  }
}
```

#### Tuple
```hcl
# Tuple (ordered collection of different types)
server_info = ["web-server", "t2.micro", 2, true]
```

## Expressions

### 1. **String Interpolation**
```hcl
# Basic interpolation
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.instance_type
  
  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# Complex interpolation
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${random_id.bucket_suffix.hex}"
}
```

### 2. **Arithmetic Operations**
```hcl
# Basic arithmetic
locals {
  total_instances = var.web_instances + var.app_instances
  half_memory     = var.memory_gb / 2
  double_cpu      = var.cpu_cores * 2
  remaining       = var.total_budget - var.used_budget
}

# Modulo operation
locals {
  is_even = var.number % 2 == 0
}
```

### 3. **Comparison Operations**
```hcl
# Equality
locals {
  is_production = var.environment == "prod"
  not_dev       = var.environment != "dev"
}

# Numerical comparison
locals {
  is_large_instance = var.cpu_cores > 4
  is_small_memory   = var.memory_gb <= 8
  within_budget     = var.cost < var.budget
}
```

### 4. **Logical Operations**
```hcl
# AND, OR, NOT
locals {
  deploy_monitoring = var.environment == "prod" && var.enable_monitoring
  skip_backup      = var.environment == "dev" || var.temporary_instance
  disable_feature  = !var.enable_feature
}
```

### 5. **Conditional Expressions**
```hcl
# Ternary operator
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  monitoring    = var.environment == "prod" ? true : false
}

# Nested conditionals
locals {
  instance_type = var.environment == "prod" ? "t3.large" : (
    var.environment == "staging" ? "t3.medium" : "t3.micro"
  )
}
```

## Functions

### 1. **String Functions**
```hcl
locals {
  # String manipulation
  upper_name    = upper(var.project_name)
  lower_name    = lower(var.project_name)
  title_name    = title(var.project_name)
  
  # String formatting
  padded_number = format("%03d", var.instance_number)
  formatted_msg = format("Instance %s in %s", var.name, var.region)
  
  # String operations
  trimmed      = trim(var.user_input, " ")
  replaced     = replace(var.string_with_spaces, " ", "-")
  substring    = substr(var.long_string, 0, 10)
  
  # String tests
  starts_with_web = startswith(var.hostname, "web")
  ends_with_com   = endswith(var.domain, ".com")
  contains_prod   = contains(var.environment_list, "prod")
}
```

### 2. **Collection Functions**
```hcl
locals {
  # List operations
  first_az     = element(var.availability_zones, 0)
  list_length  = length(var.availability_zones)
  joined_azs   = join(",", var.availability_zones)
  sorted_list  = sort(var.unsorted_list)
  unique_items = distinct(var.list_with_duplicates)
  
  # Map operations
  map_keys     = keys(var.tags)
  map_values   = values(var.tags)
  merged_tags  = merge(var.default_tags, var.custom_tags)
  
  # Set operations
  az_set       = toset(var.availability_zones)
  
  # Filtering
  prod_instances = [
    for instance in var.instances : instance
    if instance.environment == "prod"
  ]
}
```

### 3. **Type Conversion Functions**
```hcl
locals {
  # Type conversions
  string_to_number = tonumber(var.string_number)
  number_to_string = tostring(var.numeric_value)
  list_to_set      = toset(var.list_with_duplicates)
  map_to_list      = values(var.tag_map)
  
  # JSON operations
  json_string = jsonencode(var.complex_object)
  parsed_json = jsondecode(var.json_string)
  
  # Base64 operations
  encoded_data = base64encode(var.plain_text)
  decoded_data = base64decode(var.encoded_text)
}
```

### 4. **Date and Time Functions**
```hcl
locals {
  # Current timestamp
  current_time = timestamp()
  
  # Formatted time
  formatted_time = formatdate("YYYY-MM-DD", timestamp())
  
  # Time calculations
  future_time = timeadd(timestamp(), "24h")
}
```

### 5. **Filesystem Functions**
```hcl
locals {
  # File operations
  file_content    = file("${path.module}/config.txt")
  template_result = templatefile("${path.module}/template.tpl", {
    name = var.instance_name
    port = var.port
  })
  
  # Path operations
  current_dir = path.module
  root_dir    = path.root
  current_cwd = path.cwd
  
  # File existence
  config_exists = fileexists("${path.module}/config.yaml")
}
```

## Advanced Syntax

### 1. **For Expressions**
```hcl
# List comprehension
locals {
  # Transform list
  uppercase_names = [for name in var.server_names : upper(name)]
  
  # Filter and transform
  prod_servers = [
    for server in var.servers : server.name
    if server.environment == "prod"
  ]
  
  # Create map from list
  server_map = {
    for server in var.servers : server.name => server.ip
  }
  
  # Conditional transformation
  server_configs = [
    for server in var.servers : {
      name = server.name
      type = server.environment == "prod" ? "t3.large" : "t3.micro"
    }
  ]
}
```

### 2. **Splat Expressions**
```hcl
# Extract attribute from list of objects
locals {
  # Get all instance IDs
  instance_ids = aws_instance.web[*].id
  
  # Get all private IPs
  private_ips = aws_instance.web[*].private_ip
  
  # Nested attribute access
  subnet_ids = aws_instance.web[*].subnet_id
  
  # Conditional splat
  running_instances = [
    for instance in aws_instance.web : instance.id
    if instance.instance_state == "running"
  ]
}
```

### 3. **Dynamic Blocks**
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic tags
  dynamic "tag" {
    for_each = var.tags
    content {
      key   = tag.key
      value = tag.value
    }
  }
}
```

### 4. **Validation Rules**
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 type."
  }
  
  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must start with t2. or t3."
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

## Best Practices

### 1. **Formatting**
```hcl
# Use consistent indentation (2 spaces)
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# Align arguments
resource "aws_security_group" "web" {
  name_prefix = "web-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id
}
```

### 2. **Naming Conventions**
```hcl
# Use snake_case for all identifiers
variable "instance_type" {}        # Good
variable "instanceType" {}         # Bad

# Use descriptive names
resource "aws_instance" "web_server" {}  # Good
resource "aws_instance" "i1" {}          # Bad

# Use consistent prefixes
variable "web_instance_type" {}
variable "web_instance_count" {}
variable "web_security_group_id" {}
```

### 3. **Comments and Documentation**
```hcl
# Main web server instance
# This instance hosts the primary application
resource "aws_instance" "web" {
  ami           = "ami-12345678"  # Latest Amazon Linux 2
  instance_type = "t2.micro"     # Free tier eligible
  
  # Security configuration
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "WebServer"
    Environment = var.environment
    # Managed by Terraform - do not modify manually
  }
}
```

### 4. **Error Handling**
```hcl
# Use try() function for safe operations
locals {
  # Safe map access
  instance_name = try(var.instance_config.name, "default-name")
  
  # Safe type conversion
  port_number = try(tonumber(var.port_string), 80)
  
  # Safe file reading
  config_content = try(file("config.yaml"), "default: config")
}

# Use can() for validation
variable "cidr_block" {
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

## Common Patterns

### 1. **Environment-Specific Configuration**
```hcl
locals {
  environment_config = {
    dev = {
      instance_type = "t2.micro"
      instance_count = 1
      monitoring = false
    }
    staging = {
      instance_type = "t3.small"
      instance_count = 2
      monitoring = true
    }
    prod = {
      instance_type = "t3.large"
      instance_count = 3
      monitoring = true
    }
  }
  
  config = local.environment_config[var.environment]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  ami           = "ami-12345678"
  instance_type = local.config.instance_type
  monitoring    = local.config.monitoring
}
```

### 2. **Resource Tagging**
```hcl
locals {
  # Standard tags applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Merge common tags with resource-specific tags
  tags = merge(local.common_tags, {
    Name = "web-server"
    Role = "webserver"
  })
}
```

### 3. **Conditional Resource Creation**
```hcl
# Create resource only in production
resource "aws_cloudwatch_log_group" "app_logs" {
  count = var.environment == "prod" ? 1 : 0
  
  name              = "/aws/application/${var.app_name}"
  retention_in_days = 30
}

# Create multiple resources based on condition
resource "aws_instance" "web" {
  count = var.create_instances ? var.instance_count : 0
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
```

## Conclusion

HCL syntax provides a powerful and flexible way to define infrastructure. Understanding its data types, expressions, functions, and advanced features is essential for writing effective Terraform configurations. Follow best practices for formatting, naming, and documentation to create maintainable and readable code.