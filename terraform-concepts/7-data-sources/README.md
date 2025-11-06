# Terraform Data Sources - Complete Guide

## What are Data Sources?

Data sources in Terraform allow you to fetch information about existing infrastructure that was created outside of your current Terraform configuration. They provide read-only access to external data and resources.

## Data Source Syntax

### Basic Structure
```hcl
data "data_source_type" "name" {
  # Configuration arguments
  argument1 = value1
  argument2 = value2
  
  # Filters and search criteria
  filter {
    name   = "filter_name"
    values = ["filter_value"]
  }
}
```

### Using Data Source
```hcl
# Reference data source attributes
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.selected.id
}
```

## Common AWS Data Sources

### 1. **AMI Data Source**
```hcl
# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get specific AMI by name
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Use in resource
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "Web Server"
    AMI  = data.aws_ami.amazon_linux.name
  }
}
```

### 2. **VPC and Networking Data Sources**
```hcl
# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get VPC by tag
data "aws_vpc" "main" {
  tags = {
    Name = "main-vpc"
  }
}

# Get VPC by CIDR
data "aws_vpc" "selected" {
  cidr_block = "10.0.0.0/16"
}

# Get subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "Public"
  }
}

# Get specific subnet
data "aws_subnet" "selected" {
  id = "subnet-12345678"
}

# Get subnet by availability zone
data "aws_subnet" "az_a" {
  vpc_id            = data.aws_vpc.main.id
  availability_zone = "us-west-2a"
  
  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

# Get internet gateway
data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
```

### 3. **Security Groups**
```hcl
# Get security group by name
data "aws_security_group" "web" {
  name   = "web-security-group"
  vpc_id = data.aws_vpc.main.id
}

# Get security group by tag
data "aws_security_group" "database" {
  tags = {
    Name = "database-sg"
    Tier = "Database"
  }
}

# Get multiple security groups
data "aws_security_groups" "web_sgs" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Tier = "Web"
  }
}
```

### 4. **Availability Zones**
```hcl
# Get all available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get AZs with specific services
data "aws_availability_zones" "rds_available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Use in resources
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### 5. **Route Tables**
```hcl
# Get route table by subnet association
data "aws_route_table" "public" {
  subnet_id = data.aws_subnet.public.id
}

# Get route table by tag
data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.main.id
  
  tags = {
    Name = "main-route-table"
  }
}

# Get multiple route tables
data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.main.id
  
  tags = {
    Type = "Private"
  }
}
```

## Account and Region Information

### 1. **Current Account and Region**
```hcl
# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Get partition (aws, aws-cn, aws-us-gov)
data "aws_partition" "current" {}

# Use in resources
resource "aws_s3_bucket" "logs" {
  bucket = "${data.aws_caller_identity.current.account_id}-logs-${data.aws_region.current.name}"
  
  tags = {
    Account   = data.aws_caller_identity.current.account_id
    Region    = data.aws_region.current.name
    Partition = data.aws_partition.current.partition
  }
}
```

### 2. **IAM Information**
```hcl
# Get IAM policy document
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# Get existing IAM role
data "aws_iam_role" "existing" {
  name = "existing-role"
}

# Get IAM policy
data "aws_iam_policy" "s3_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
```

## Database Data Sources

### 1. **RDS**
```hcl
# Get RDS instance
data "aws_db_instance" "database" {
  db_instance_identifier = "myapp-database"
}

# Get RDS subnet group
data "aws_db_subnet_group" "database" {
  name = "database-subnet-group"
}

# Get RDS parameter group
data "aws_db_parameter_group" "mysql" {
  name = "mysql-parameters"
}
```

### 2. **DynamoDB**
```hcl
# Get DynamoDB table
data "aws_dynamodb_table" "users" {
  name = "users-table"
}
```

## Load Balancer Data Sources

```hcl
# Get Application Load Balancer
data "aws_lb" "main" {
  name = "main-alb"
}

# Get ALB by tag
data "aws_lb" "web" {
  tags = {
    Environment = "production"
    Tier        = "web"
  }
}

# Get target group
data "aws_lb_target_group" "web" {
  name = "web-target-group"
}

# Get listener
data "aws_lb_listener" "web" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 443
}
```

## Certificate and DNS Data Sources

### 1. **ACM Certificates**
```hcl
# Get SSL certificate
data "aws_acm_certificate" "main" {
  domain   = "example.com"
  statuses = ["ISSUED"]
}

# Get certificate by tag
data "aws_acm_certificate" "wildcard" {
  domain = "*.example.com"
  
  tags = {
    Environment = "production"
  }
}
```

### 2. **Route53**
```hcl
# Get hosted zone
data "aws_route53_zone" "main" {
  name         = "example.com"
  private_zone = false
}

# Get private hosted zone
data "aws_route53_zone" "private" {
  name         = "internal.example.com"
  private_zone = true
  vpc_id       = data.aws_vpc.main.id
}
```

## Storage Data Sources

### 1. **S3**
```hcl
# Get S3 bucket
data "aws_s3_bucket" "logs" {
  bucket = "my-app-logs"
}

# Get S3 object
data "aws_s3_object" "config" {
  bucket = "my-config-bucket"
  key    = "app-config.json"
}
```

### 2. **EBS**
```hcl
# Get EBS volume
data "aws_ebs_volume" "data" {
  most_recent = true
  
  filter {
    name   = "tag:Name"
    values = ["data-volume"]
  }
}

# Get EBS snapshot
data "aws_ebs_snapshot" "backup" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "tag:Purpose"
    values = ["backup"]
  }
}
```

## Kubernetes Data Sources

```hcl
# Get EKS cluster
data "aws_eks_cluster" "main" {
  name = "my-cluster"
}

# Get EKS cluster auth
data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}

# Get node group
data "aws_eks_node_group" "workers" {
  cluster_name    = data.aws_eks_cluster.main.name
  node_group_name = "worker-nodes"
}
```

## Advanced Data Source Patterns

### 1. **Conditional Data Sources**
```hcl
# Use data source conditionally
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  
  tags = {
    Name = var.existing_vpc_name
  }
}

# Reference conditionally
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id
}
```

### 2. **Dynamic Data Source Filtering**
```hcl
# Dynamic filtering based on variables
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  dynamic "filter" {
    for_each = var.subnet_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

variable "subnet_filters" {
  description = "Additional subnet filters"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = []
}
```

### 3. **Data Source Validation**
```hcl
# Validate data source results
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["${var.app_name}-*"]
  }
}

# Ensure AMI was found
locals {
  ami_id = length(data.aws_ami.app.id) > 0 ? data.aws_ami.app.id : null
}

resource "aws_instance" "app" {
  count = local.ami_id != null ? 1 : 0
  
  ami           = local.ami_id
  instance_type = "t3.micro"
}
```

## Cross-Provider Data Sources

### 1. **External Data Source**
```hcl
# Get data from external program
data "external" "git_info" {
  program = ["bash", "-c", "echo '{\"commit\":\"'$(git rev-parse HEAD)'\",\"branch\":\"'$(git branch --show-current)'\"}'"]
}

# Use external data
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    GitCommit = data.external.git_info.result.commit
    GitBranch = data.external.git_info.result.branch
  }
}
```

### 2. **HTTP Data Source**
```hcl
# Get data from HTTP endpoint
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Use HTTP data
resource "aws_security_group" "web" {
  name_prefix = "web-"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
}
```

### 3. **Template Data Source**
```hcl
# Render template with data
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh.tpl")
  
  vars = {
    server_name = var.server_name
    environment = var.environment
    region      = data.aws_region.current.name
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  user_data     = data.template_file.user_data.rendered
}
```

## Data Source Best Practices

### 1. **Error Handling**
```hcl
# Use try() for safe data source access
locals {
  vpc_id = try(data.aws_vpc.existing[0].id, aws_vpc.new[0].id)
}

# Validate data source results
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["${var.app_name}-*"]
  }
}

# Check if AMI exists
resource "null_resource" "ami_check" {
  count = length(data.aws_ami.app.id) == 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'Error: No AMI found for ${var.app_name}' && exit 1"
  }
}
```

### 2. **Performance Optimization**
```hcl
# Cache data source results in locals
locals {
  # Fetch once, use multiple times
  vpc_info = data.aws_vpc.main
  
  # Computed values
  public_subnets = [
    for subnet in data.aws_subnets.public.ids :
    subnet if can(regex("public", subnet))
  ]
}
```

### 3. **Documentation**
```hcl
# Document data source dependencies
data "aws_vpc" "main" {
  # This VPC must exist before running Terraform
  # Created by: network-infrastructure project
  # Contact: network-team@company.com
  tags = {
    Name = "main-vpc"
  }
}
```

## Troubleshooting Data Sources

### Common Issues

#### 1. **Data Source Not Found**
```bash
# Error: No matching resources found
# Solution: Check filters and ensure resource exists
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["correct-ami-name-*"]  # Fix the name pattern
  }
}
```

#### 2. **Multiple Resources Found**
```bash
# Error: Multiple resources match
# Solution: Add more specific filters
data "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = data.aws_vpc.main.id  # Add VPC filter
}
```

#### 3. **Permission Issues**
```bash
# Error: Access denied
# Solution: Ensure IAM permissions for describe operations
# Required permissions: ec2:Describe*, iam:Get*, s3:List*, etc.
```

### Debug Data Sources
```bash
# Show data source values
terraform console
> data.aws_ami.amazon_linux.id
> data.aws_vpc.main.cidr_block

# Refresh data sources
terraform refresh

# Plan to see data source changes
terraform plan
```

## Conclusion

Data sources are essential for integrating existing infrastructure with Terraform configurations. They provide read-only access to external resources and enable dynamic configuration based on current infrastructure state. Use appropriate filters, handle errors gracefully, and document dependencies to create robust and maintainable configurations.