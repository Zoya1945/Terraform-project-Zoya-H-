# HCL Syntax Examples

# Variables demonstrating different types
variable "string_example" {
  description = "String variable example"
  type        = string
  default     = "hello-world"
}

variable "number_example" {
  description = "Number variable example"
  type        = number
  default     = 42
}

variable "boolean_example" {
  description = "Boolean variable example"
  type        = bool
  default     = true
}

variable "list_example" {
  description = "List variable example"
  type        = list(string)
  default     = ["item1", "item2", "item3"]
}

variable "map_example" {
  description = "Map variable example"
  type        = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
  }
}

variable "object_example" {
  description = "Object variable example"
  type = object({
    name    = string
    age     = number
    active  = bool
    tags    = list(string)
  })
  default = {
    name   = "example"
    age    = 25
    active = true
    tags   = ["tag1", "tag2"]
  }
}

# Local values demonstrating expressions
locals {
  # String interpolation
  server_name = "${var.string_example}-server"
  
  # Arithmetic operations
  double_number = var.number_example * 2
  half_number   = var.number_example / 2
  
  # Conditional expressions
  environment_type = var.boolean_example ? "production" : "development"
  
  # Function usage
  uppercase_name = upper(var.string_example)
  list_length    = length(var.list_example)
  
  # For expressions
  uppercase_list = [for item in var.list_example : upper(item)]
  
  # Map transformation
  prefixed_map = {
    for k, v in var.map_example : k => "prefix-${v}"
  }
  
  # Complex expressions
  filtered_list = [
    for item in var.list_example : item
    if length(item) > 4
  ]
}

# Resource with dynamic blocks
resource "null_resource" "example" {
  # Dynamic provisioner blocks
  dynamic "provisioner" {
    for_each = var.boolean_example ? ["local-exec"] : []
    content {
      local-exec {
        command = "echo 'Hello from ${local.server_name}'"
      }
    }
  }
  
  triggers = {
    server_name = local.server_name
    timestamp   = timestamp()
  }
}

# Output values
output "string_interpolation" {
  description = "Example of string interpolation"
  value       = "Server: ${local.server_name}, Number: ${local.double_number}"
}

output "conditional_output" {
  description = "Example of conditional expression"
  value       = local.environment_type
}

output "function_results" {
  description = "Results of various functions"
  value = {
    uppercase_name = local.uppercase_name
    list_length    = local.list_length
    uppercase_list = local.uppercase_list
  }
}

output "complex_expressions" {
  description = "Results of complex expressions"
  value = {
    prefixed_map  = local.prefixed_map
    filtered_list = local.filtered_list
  }
}