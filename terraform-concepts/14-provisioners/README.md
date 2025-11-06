# Terraform Provisioners - Complete Guide

## What are Provisioners?

Provisioners are used to execute scripts on a local or remote machine as part of resource creation or destruction. They are a "last resort" and should be avoided when possible in favor of native Terraform resources.

## Types of Provisioners

### 1. **File Provisioner**
Copies files or directories from local machine to remote machine.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "my-keypair"
  
  # Copy single file
  provisioner "file" {
    source      = "app.conf"
    destination = "/tmp/app.conf"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Copy directory
  provisioner "file" {
    source      = "configs/"
    destination = "/tmp"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Copy with content
  provisioner "file" {
    content     = templatefile("${path.module}/script.sh.tpl", {
      server_name = "web-server"
      port        = 80
    })
    destination = "/tmp/setup.sh"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

### 2. **Remote-Exec Provisioner**
Executes commands on remote machine via SSH or WinRM.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "my-keypair"
  
  # Inline commands
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "echo '<h1>Hello World</h1>' | sudo tee /var/www/html/index.html"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Execute script
  provisioner "remote-exec" {
    script = "${path.module}/setup.sh"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Execute multiple scripts
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/install.sh",
      "${path.module}/configure.sh",
      "${path.module}/start.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

### 3. **Local-Exec Provisioner**
Executes commands on local machine where Terraform is running.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Simple command
  provisioner "local-exec" {
    command = "echo 'Instance ${self.id} created'"
  }
  
  # Complex command with variables
  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${self.id} --tags Key=CreatedBy,Value=Terraform"
    
    environment = {
      AWS_DEFAULT_REGION = "us-west-2"
    }
  }
  
  # Working directory
  provisioner "local-exec" {
    command     = "./deploy.sh ${self.public_ip}"
    working_dir = "${path.module}/scripts"
  }
  
  # Interpreter
  provisioner "local-exec" {
    command     = "python3 notify.py --instance-id ${self.id}"
    interpreter = ["python3", "-c"]
  }
}
```

## Connection Configuration

### 1. **SSH Connection**
```hcl
connection {
  type        = "ssh"
  user        = "ec2-user"
  password    = var.password          # Not recommended
  private_key = file("~/.ssh/id_rsa") # Recommended
  host        = self.public_ip
  port        = 22
  timeout     = "5m"
  
  # SSH agent
  agent = true
  
  # Bastion host
  bastion_host        = "bastion.example.com"
  bastion_user        = "bastion-user"
  bastion_private_key = file("~/.ssh/bastion_key")
  
  # Host key checking
  host_key = "ssh-rsa AAAAB3NzaC1yc2E..."
}
```

### 2. **WinRM Connection (Windows)**
```hcl
connection {
  type     = "winrm"
  user     = "Administrator"
  password = var.admin_password
  host     = self.public_ip
  port     = 5985
  https    = false
  insecure = true
  timeout  = "10m"
  
  # HTTPS WinRM
  # port     = 5986
  # https    = true
  # insecure = false
}
```

## Provisioner Timing

### 1. **Creation-Time Provisioners**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Runs during resource creation (default)
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

### 2. **Destruction-Time Provisioners**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Runs during resource destruction
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} is being destroyed'"
  }
  
  # Cleanup script on destroy
  provisioner "remote-exec" {
    when = destroy
    
    inline = [
      "sudo systemctl stop httpd",
      "sudo rm -rf /var/www/html/*"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

## Error Handling

### 1. **Failure Behavior**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Continue on failure (default: fail)
  provisioner "remote-exec" {
    on_failure = continue
    
    inline = [
      "sudo yum install -y optional-package || true"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Fail on error (default behavior)
  provisioner "remote-exec" {
    on_failure = fail
    
    inline = [
      "sudo yum install -y required-package"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

## Advanced Provisioner Patterns

### 1. **Conditional Provisioners**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Conditional provisioner using count
  dynamic "provisioner" {
    for_each = var.install_monitoring ? ["monitoring"] : []
    content {
      remote-exec {
        inline = [
          "curl -sSL https://agent.monitoring.com/install.sh | bash"
        ]
        
        connection {
          type        = "ssh"
          user        = "ec2-user"
          private_key = file("~/.ssh/id_rsa")
          host        = self.public_ip
        }
      }
    }
  }
}
```

### 2. **Multi-Step Provisioning**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  # Step 1: Copy configuration files
  provisioner "file" {
    source      = "${path.module}/configs/"
    destination = "/tmp/configs"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Step 2: Install packages
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd php mysql"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Step 3: Configure services
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/configs/httpd.conf /etc/httpd/conf/",
      "sudo cp /tmp/configs/php.ini /etc/",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  # Step 4: Verify installation
  provisioner "remote-exec" {
    inline = [
      "curl -f http://localhost/ || exit 1",
      "php -v || exit 1"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

### 3. **Template-Based Provisioning**
```hcl
# Template file: setup.sh.tpl
# #!/bin/bash
# SERVER_NAME="${server_name}"
# DATABASE_HOST="${db_host}"
# API_KEY="${api_key}"
# 
# echo "Setting up $SERVER_NAME..."
# echo "DATABASE_HOST=$DATABASE_HOST" >> /etc/environment
# echo "API_KEY=$API_KEY" >> /etc/environment

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  provisioner "file" {
    content = templatefile("${path.module}/setup.sh.tpl", {
      server_name = "web-${count.index + 1}"
      db_host     = aws_db_instance.main.endpoint
      api_key     = var.api_key
    })
    destination = "/tmp/setup.sh"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

## Real-World Examples

### 1. **Web Server Setup**
```hcl
resource "aws_instance" "web" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  
  # Copy application files
  provisioner "file" {
    source      = "${path.module}/app/"
    destination = "/tmp/app"
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
  
  # Install and configure web server
  provisioner "remote-exec" {
    inline = [
      # Update system
      "sudo yum update -y",
      
      # Install packages
      "sudo yum install -y httpd php mysql",
      
      # Copy application
      "sudo cp -r /tmp/app/* /var/www/html/",
      "sudo chown -R apache:apache /var/www/html/",
      
      # Configure Apache
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      
      # Configure firewall
      "sudo firewall-cmd --permanent --add-service=http",
      "sudo firewall-cmd --permanent --add-service=https",
      "sudo firewall-cmd --reload"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
  
  # Verify installation
  provisioner "local-exec" {
    command = "curl -f http://${self.public_ip}/ || exit 1"
  }
  
  tags = {
    Name = "web-server"
  }
}
```

### 2. **Database Initialization**
```hcl
resource "aws_db_instance" "main" {
  identifier = "myapp-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_encrypted = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  skip_final_snapshot = true
}

# Initialize database after creation
resource "null_resource" "db_init" {
  depends_on = [aws_db_instance.main]
  
  provisioner "local-exec" {
    command = <<-EOT
      mysql -h ${aws_db_instance.main.endpoint} \
            -u ${var.db_username} \
            -p${var.db_password} \
            ${var.db_name} < ${path.module}/schema.sql
    EOT
    
    environment = {
      MYSQL_PWD = var.db_password
    }
  }
  
  # Re-run if schema changes
  triggers = {
    schema_hash = filemd5("${path.module}/schema.sql")
  }
}
```

## Best Practices

### 1. **Avoid Provisioners When Possible**
```hcl
# Bad - using provisioner for user data
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y httpd",
      "sudo systemctl start httpd"
    ]
  }
}

# Good - using user_data
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
  EOF
  )
}
```

### 2. **Use null_resource for Orchestration**
```hcl
# Separate provisioning logic
resource "null_resource" "app_deployment" {
  depends_on = [aws_instance.web]
  
  provisioner "local-exec" {
    command = "./deploy.sh ${aws_instance.web.public_ip}"
  }
  
  triggers = {
    instance_id = aws_instance.web.id
    app_version = var.app_version
  }
}
```

### 3. **Error Handling and Retries**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  provisioner "remote-exec" {
    inline = [
      # Retry package installation
      "for i in {1..3}; do sudo yum install -y httpd && break || sleep 10; done",
      
      # Check service status
      "sudo systemctl start httpd",
      "sudo systemctl is-active httpd || exit 1"
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

### 4. **Secure Connection Handling**
```hcl
# Use variables for sensitive data
variable "private_key_path" {
  description = "Path to private key"
  type        = string
  sensitive   = true
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  provisioner "remote-exec" {
    inline = ["echo 'Connected successfully'"]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}
```

## Troubleshooting Provisioners

### Common Issues

#### 1. **Connection Failures**
```bash
# Error: timeout waiting for SSH
# Solutions:
# - Check security group allows SSH (port 22)
# - Verify key pair is correct
# - Ensure instance has public IP
# - Check network ACLs
```

#### 2. **Permission Issues**
```bash
# Error: permission denied
# Solutions:
# - Use correct user (ec2-user, ubuntu, admin)
# - Check file permissions
# - Use sudo for privileged operations
```

#### 3. **Script Failures**
```bash
# Error: script execution failed
# Solutions:
# - Add error checking in scripts
# - Use absolute paths
# - Set proper environment variables
```

### Debug Provisioners
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Test SSH connection manually
ssh -i ~/.ssh/id_rsa ec2-user@<instance-ip>

# Check provisioner scripts locally
bash -x script.sh
```

## Alternatives to Provisioners

### 1. **Cloud-Init / User Data**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname = "web-server"
  }))
}
```

### 2. **Configuration Management Tools**
- **Ansible**: Use ansible-playbook with local-exec
- **Chef**: Bootstrap with knife
- **Puppet**: Use puppet agent

### 3. **Container Images**
```hcl
# Use pre-configured AMIs or container images
resource "aws_instance" "web" {
  ami           = "ami-preconfigured-web-server"
  instance_type = "t3.micro"
}
```

## Conclusion

Provisioners should be used sparingly and only when native Terraform resources or cloud-init cannot accomplish the task. When using provisioners, ensure proper error handling, use secure connections, and consider alternatives like configuration management tools or pre-built images for complex setups.