# Module Outputs

output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.web[*].private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "elastic_ips" {
  description = "List of Elastic IP addresses"
  value       = aws_eip.web[*].public_ip
}

output "instance_details" {
  description = "Complete instance information"
  value = {
    for i, instance in aws_instance.web : i => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      az         = instance.availability_zone
    }
  }
}