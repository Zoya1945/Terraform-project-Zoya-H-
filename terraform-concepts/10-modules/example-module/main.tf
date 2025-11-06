# Simple Web Server Module

# Security Group
resource "aws_security_group" "web" {
  name_prefix = "${var.name}-web-"
  description = "Security group for ${var.name} web server"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name}-web-sg"
  })
}

# EC2 Instance
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    server_name = "${var.name}-${count.index + 1}"
  }))
  
  tags = merge(var.tags, {
    Name = "${var.name}-web-${count.index + 1}"
  })
}

# Elastic IP (optional)
resource "aws_eip" "web" {
  count = var.create_eip ? var.instance_count : 0
  
  instance = aws_instance.web[count.index].id
  domain   = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name}-eip-${count.index + 1}"
  })
}