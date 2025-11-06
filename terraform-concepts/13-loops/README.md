# Terraform Loops - Complete Guide

## Count Meta-Argument

### 1. **Basic Count Usage**
```hcl
# Create multiple instances
resource "aws_instance" "web" {
  count = 3
  
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

# Reference specific instances
output "first_instance_ip" {
  value = aws_instance.web[0].public_ip
}

# Reference all instances
output "all_instance_ips" {
  value = aws_instance.web[*].public_ip
}
```

### 2. **Conditional Count**
```hcl
# Create resources conditionally
resource "aws_eip" "web" {
  count = var.create_eip ? var.instance_count : 0
  
  instance = aws_instance.web[count.index].id
  domain   = "vpc"
}
```

## For Each Meta-Argument

### 1. **For Each with Set**
```hcl
# Create resources from set
resource "aws_instance" "servers" {
  for_each = toset(["web", "app", "db"])
  
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "${each.key}-server"
    Role = each.key
  }
}

# Reference specific instance
output "web_server_ip" {
  value = aws_instance.servers["web"].public_ip
}
```

### 2. **For Each with Map**
```hcl
# Create resources from map
resource "aws_instance" "servers" {
  for_each = {
    web = "t3.micro"
    app = "t3.small"
    db  = "t3.medium"
  }
  
  ami           = "ami-12345678"
  instance_type = each.value
  
  tags = {
    Name = "${each.key}-server"
    Type = each.value
  }
}
```

## For Expressions

### 1. **List Transformations**
```hcl
locals {
  server_names = ["web-1", "web-2", "app-1", "db-1"]
  
  # Transform list
  uppercase_names = [for name in local.server_names : upper(name)]
  
  # Filter and transform
  web_servers = [
    for name in local.server_names : name
    if startswith(name, "web")
  ]
  
  # Complex transformation
  server_configs = [
    for name in local.server_names : {
      name = name
      type = split("-", name)[0]
      size = startswith(name, "db") ? "large" : "small"
    }
  ]
}
```

### 2. **Map Transformations**
```hcl
locals {
  servers = {
    web-1 = { type = "web", size = "small" }
    web-2 = { type = "web", size = "small" }
    app-1 = { type = "app", size = "medium" }
    db-1  = { type = "db", size = "large" }
  }
  
  # Transform map values
  instance_types = {
    for name, config in local.servers : name => config.size == "small" ? "t3.micro" : (
      config.size == "medium" ? "t3.small" : "t3.large"
    )
  }
  
  # Filter map
  web_servers = {
    for name, config in local.servers : name => config
    if config.type == "web"
  }
  
  # Group by type
  servers_by_type = {
    for name, config in local.servers : config.type => name...
  }
}
```

## Dynamic Blocks

### 1. **Basic Dynamic Blocks**
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

### 2. **Nested Dynamic Blocks**
```hcl
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  
  dynamic "default_action" {
    for_each = var.listener_actions
    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.target_group_arn
      
      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
        }
      }
    }
  }
}
```

## Advanced Loop Patterns

### 1. **Flatten Function**
```hcl
locals {
  environments = ["dev", "staging", "prod"]
  services     = ["web", "app", "db"]
  
  # Create all combinations
  all_combinations = flatten([
    for env in local.environments : [
      for svc in local.services : {
        environment = env
        service     = svc
        name        = "${env}-${svc}"
      }
    ]
  ])
  
  # Create resources for all combinations
  instance_configs = {
    for combo in local.all_combinations : combo.name => {
      environment = combo.environment
      service     = combo.service
      instance_type = combo.service == "db" ? "t3.medium" : "t3.micro"
    }
  }
}
```

### 2. **Conditional Loops**
```hcl
locals {
  # Create subnets only for specified AZs
  subnet_configs = {
    for i, az in var.availability_zones : "subnet-${i}" => {
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, i)
      availability_zone = az
    }
    if contains(var.enabled_azs, az)
  }
  
  # Create security group rules based on environment
  security_rules = concat(
    # Base rules for all environments
    [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ],
    # Additional rules for production
    var.environment == "prod" ? [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ] : []
  )
}
```

## Real-World Examples

### 1. **Multi-Environment Infrastructure**
```hcl
variable "environments" {
  type = map(object({
    instance_count = number
    instance_type  = string
    subnets        = list(string)
  }))
  default = {
    dev = {
      instance_count = 1
      instance_type  = "t3.micro"
      subnets        = ["subnet-dev1"]
    }
    prod = {
      instance_count = 3
      instance_type  = "t3.large"
      subnets        = ["subnet-prod1", "subnet-prod2", "subnet-prod3"]
    }
  }
}

# Create instances for each environment
resource "aws_instance" "app" {
  for_each = var.environments
  
  count = each.value.instance_count
  
  ami           = "ami-12345678"
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnets[count.index % length(each.value.subnets)]
  
  tags = {
    Name        = "${each.key}-app-${count.index + 1}"
    Environment = each.key
  }
}
```

### 2. **Dynamic Security Group Rules**
```hcl
variable "applications" {
  type = map(object({
    ports = list(number)
    cidrs = list(string)
  }))
  default = {
    web = {
      ports = [80, 443]
      cidrs = ["0.0.0.0/0"]
    }
    api = {
      ports = [8080, 8443]
      cidrs = ["10.0.0.0/8"]
    }
  }
}

# Create security groups for each application
resource "aws_security_group" "app" {
  for_each = var.applications
  
  name_prefix = "${each.key}-"
  
  dynamic "ingress" {
    for_each = [
      for port in each.value.ports : {
        port  = port
        cidrs = each.value.cidrs
      }
    ]
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidrs
    }
  }
}
```

### 3. **Complex Data Transformation**
```hcl
locals {
  # Raw configuration
  raw_servers = [
    { name = "web-1", env = "prod", type = "web" },
    { name = "web-2", env = "prod", type = "web" },
    { name = "api-1", env = "prod", type = "api" },
    { name = "db-1", env = "prod", type = "db" }
  ]
  
  # Group servers by type
  servers_by_type = {
    for server in local.raw_servers : server.type => server...
  }
  
  # Create load balancer target groups
  target_groups = {
    for type, servers in local.servers_by_type : type => {
      name    = "${type}-tg"
      port    = type == "web" ? 80 : (type == "api" ? 8080 : 3306)
      targets = [for server in servers : server.name]
    }
    if type != "db"  # Don't create target group for database
  }
  
  # Generate instance configurations
  instance_configs = {
    for server in local.raw_servers : server.name => {
      instance_type = server.type == "db" ? "t3.large" : "t3.medium"
      monitoring    = server.env == "prod"
      backup        = server.type == "db"
    }
  }
}
```

## Performance Considerations

### 1. **Efficient Loops**
```hcl
# Good - single loop
locals {
  subnet_configs = {
    for i in range(length(var.availability_zones)) : "subnet-${i}" => {
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, i)
      availability_zone = var.availability_zones[i]
      public           = i < var.public_subnet_count
    }
  }
}

# Less efficient - nested loops
locals {
  subnet_configs = merge([
    for i, az in var.availability_zones : {
      for type in ["public", "private"] : "${type}-subnet-${i}" => {
        cidr_block        = cidrsubnet(var.vpc_cidr, 8, i + (type == "private" ? 10 : 0))
        availability_zone = az
        public           = type == "public"
      }
    }
  ]...)
}
```

### 2. **Avoiding Resource Churn**
```hcl
# Use for_each instead of count for stable resources
resource "aws_instance" "web" {
  for_each = var.server_configs  # Stable keys
  
  ami           = each.value.ami
  instance_type = each.value.type
  
  tags = {
    Name = each.key
  }
}

# Avoid count for resources that might change order
# resource "aws_instance" "web" {
#   count = length(var.server_names)  # Can cause resource recreation
# }
```

## Best Practices

### 1. **Choose the Right Loop Type**
```hcl
# Use count for simple numeric iteration
resource "aws_subnet" "public" {
  count = var.public_subnet_count
  
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
}

# Use for_each for stable, named resources
resource "aws_instance" "servers" {
  for_each = var.server_configs
  
  ami           = each.value.ami
  instance_type = each.value.type
}

# Use for expressions for data transformation
locals {
  server_ips = {
    for name, instance in aws_instance.servers : name => instance.private_ip
  }
}
```

### 2. **Readable Loop Logic**
```hcl
# Good - clear and readable
locals {
  web_servers = [
    for server in var.servers : server
    if server.type == "web"
  ]
  
  server_configs = {
    for server in local.web_servers : server.name => {
      instance_type = server.size == "large" ? "t3.large" : "t3.micro"
      monitoring    = var.environment == "prod"
    }
  }
}

# Bad - complex nested logic
locals {
  server_configs = {
    for server in var.servers : server.name => {
      instance_type = server.type == "web" ? (server.size == "large" ? "t3.large" : "t3.micro") : null
      monitoring    = server.type == "web" && var.environment == "prod"
    }
    if server.type == "web"
  }
}
```

## Conclusion

Loops in Terraform (count, for_each, for expressions, dynamic blocks) enable you to create flexible, maintainable infrastructure code. Choose the appropriate loop type based on your use case, prioritize readability, and consider performance implications when designing your loop logic.