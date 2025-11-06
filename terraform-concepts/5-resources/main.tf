# Resource Examples

# Basic resource
resource "null_resource" "basic_example" {
  triggers = {
    timestamp = timestamp()
  }
  
  provisioner "local-exec" {
    command = "echo 'Basic resource created'"
  }
}

# Resource with count
resource "null_resource" "count_example" {
  count = 3
  
  triggers = {
    index = count.index
    name  = "resource-${count.index + 1}"
  }
  
  provisioner "local-exec" {
    command = "echo 'Created resource ${count.index + 1}'"
  }
}

# Resource with for_each (set)
resource "null_resource" "for_each_set" {
  for_each = toset(["web", "app", "db"])
  
  triggers = {
    name = each.key
    type = "server"
  }
  
  provisioner "local-exec" {
    command = "echo 'Created ${each.key} server'"
  }
}

# Resource with for_each (map)
resource "null_resource" "for_each_map" {
  for_each = {
    web = "nginx"
    app = "nodejs"
    db  = "postgresql"
  }
  
  triggers = {
    name     = each.key
    software = each.value
  }
  
  provisioner "local-exec" {
    command = "echo 'Created ${each.key} server with ${each.value}'"
  }
}

# Resource with lifecycle rules
resource "null_resource" "lifecycle_example" {
  triggers = {
    version = "1.0.0"
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [triggers.version]
  }
  
  provisioner "local-exec" {
    command = "echo 'Lifecycle resource created'"
  }
}

# Resource with explicit dependencies
resource "null_resource" "dependency_target" {
  triggers = {
    name = "target"
  }
  
  provisioner "local-exec" {
    command = "echo 'Target resource created'"
  }
}

resource "null_resource" "dependency_source" {
  depends_on = [null_resource.dependency_target]
  
  triggers = {
    name = "source"
  }
  
  provisioner "local-exec" {
    command = "echo 'Source resource created after target'"
  }
}

# Conditional resource
resource "null_resource" "conditional" {
  count = var.create_conditional_resource ? 1 : 0
  
  triggers = {
    condition = "met"
  }
  
  provisioner "local-exec" {
    command = "echo 'Conditional resource created'"
  }
}

# Variables for examples
variable "create_conditional_resource" {
  description = "Whether to create conditional resource"
  type        = bool
  default     = true
}

# Outputs
output "basic_resource_id" {
  description = "ID of basic resource"
  value       = null_resource.basic_example.id
}

output "count_resource_ids" {
  description = "IDs of count resources"
  value       = null_resource.count_example[*].id
}

output "for_each_set_ids" {
  description = "IDs of for_each set resources"
  value       = { for k, v in null_resource.for_each_set : k => v.id }
}

output "for_each_map_ids" {
  description = "IDs of for_each map resources"
  value       = { for k, v in null_resource.for_each_map : k => v.id }
}