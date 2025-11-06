# Real-World Terraform Scenarios

## Scenario 1: Blue-Green Deployment

**Challenge:** Implement zero-downtime deployment using Terraform.

**Solution:**
```hcl
# variables.tf
variable "environment_color" {
  description = "Current active environment (blue or green)"
  type        = string
  default     = "blue"
}

# main.tf
locals {
  active_color   = var.environment_color
  inactive_color = var.environment_color == "blue" ? "green" : "blue"
}

# Blue environment
module "blue_environment" {
  source = "./modules/app-environment"
  
  color           = "blue"
  is_active       = local.active_color == "blue"
  instance_count  = local.active_color == "blue" ? 3 : 0
}

# Green environment
module "green_environment" {
  source = "./modules/app-environment"
  
  color           = "green"
  is_active       = local.active_color == "green"
  instance_count  = local.active_color == "green" ? 3 : 0
}

# Load balancer switches between environments
resource "aws_lb_target_group_attachment" "active" {
  count = local.active_color == "blue" ? length(module.blue_environment.instance_ids) : length(module.green_environment.instance_ids)
  
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = local.active_color == "blue" ? module.blue_environment.instance_ids[count.index] : module.green_environment.instance_ids[count.index]
}
```

**Deployment Process:**
```bash
# 1. Deploy to inactive environment
terraform apply -var="environment_color=blue"

# 2. Test inactive environment
curl http://green-env.example.com/health

# 3. Switch traffic
terraform apply -var="environment_color=green"

# 4. Cleanup old environment
terraform apply -var="environment_color=green"
```

## Scenario 2: Multi-Region Disaster Recovery

**Challenge:** Set up infrastructure across multiple regions with automated failover.

**Solution:**
```hcl
# providers.tf
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# main.tf
module "primary_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.primary
  }
  
  region           = var.primary_region
  environment      = "primary"
  enable_backups   = true
  backup_retention = 30
}

module "dr_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.dr
  }
  
  region           = var.dr_region
  environment      = "dr"
  enable_backups   = false
  backup_retention = 7
}

# Cross-region replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  
  role   = aws_iam_role.replication.arn
  bucket = module.primary_infrastructure.s3_bucket_id
  
  rule {
    id     = "replicate-to-dr"
    status = "Enabled"
    
    destination {
      bucket        = module.dr_infrastructure.s3_bucket_arn
      storage_class = "STANDARD_IA"
    }
  }
}

# Route 53 health checks and failover
resource "aws_route53_health_check" "primary" {
  fqdn                            = module.primary_infrastructure.load_balancer_dns
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
}

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name                   = module.primary_infrastructure.load_balancer_dns
    zone_id                = module.primary_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dr" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = "dr"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  alias {
    name                   = module.dr_infrastructure.load_balancer_dns
    zone_id                = module.dr_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}
```

## Scenario 3: Cost Optimization with Scheduled Resources

**Challenge:** Automatically start/stop non-production resources to save costs.

**Solution:**
```hcl
# variables.tf
variable "schedule_enabled" {
  description = "Enable resource scheduling"
  type        = bool
  default     = true
}

variable "business_hours" {
  description = "Business hours schedule"
  type = object({
    start_time = string
    end_time   = string
    timezone   = string
    weekdays   = list(string)
  })
  default = {
    start_time = "08:00"
    end_time   = "18:00"
    timezone   = "America/New_York"
    weekdays   = ["MON", "TUE", "WED", "THU", "FRI"]
  }
}

# Auto Scaling Schedule
resource "aws_autoscaling_schedule" "scale_up" {
  count = var.schedule_enabled && terraform.workspace != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-up-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 3
  recurrence             = "0 ${split(":", var.business_hours.start_time)[0]} * * ${join(",", var.business_hours.weekdays)}"
  time_zone              = var.business_hours.timezone
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_schedule" "scale_down" {
  count = var.schedule_enabled && terraform.workspace != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-down-after-hours"
  min_size               = 0
  max_size               = 2
  desired_capacity       = 0
  recurrence             = "0 ${split(":", var.business_hours.end_time)[0]} * * ${join(",", var.business_hours.weekdays)}"
  time_zone              = var.business_hours.timezone
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# RDS Instance Scheduling
resource "aws_db_instance" "main" {
  identifier = "${terraform.workspace}-database"
  
  # Skip final snapshot for non-prod to allow easy deletion
  skip_final_snapshot = terraform.workspace != "prod"
  
  # Smaller instance for non-prod
  instance_class = terraform.workspace == "prod" ? "db.t3.large" : "db.t3.micro"
  
  # Automated backups only for prod
  backup_retention_period = terraform.workspace == "prod" ? 30 : 0
  backup_window          = terraform.workspace == "prod" ? "03:00-04:00" : null
}

# Lambda function for RDS start/stop
resource "aws_lambda_function" "rds_scheduler" {
  count = var.schedule_enabled && terraform.workspace != "prod" ? 1 : 0
  
  filename         = "rds_scheduler.zip"
  function_name    = "${terraform.workspace}-rds-scheduler"
  role            = aws_iam_role.lambda_role[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  
  environment {
    variables = {
      DB_IDENTIFIER = aws_db_instance.main.identifier
    }
  }
}

# CloudWatch Events for scheduling
resource "aws_cloudwatch_event_rule" "start_rds" {
  count = var.schedule_enabled && terraform.workspace != "prod" ? 1 : 0
  
  name                = "${terraform.workspace}-start-rds"
  description         = "Start RDS during business hours"
  schedule_expression = "cron(0 ${split(":", var.business_hours.start_time)[0]} ? * ${join(",", var.business_hours.weekdays)} *)"
}

resource "aws_cloudwatch_event_target" "start_rds" {
  count = var.schedule_enabled && terraform.workspace != "prod" ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.start_rds[0].name
  target_id = "StartRDSTarget"
  arn       = aws_lambda_function.rds_scheduler[0].arn
  
  input = jsonencode({
    action = "start"
  })
}
```

## Scenario 4: Compliance and Security Automation

**Challenge:** Ensure all resources comply with security policies automatically.

**Solution:**
```hcl
# Security baseline module
module "security_baseline" {
  source = "./modules/security-baseline"
  
  environment = terraform.workspace
  
  # Security requirements
  require_encryption     = true
  require_backup        = terraform.workspace == "prod"
  require_monitoring    = true
  allowed_instance_types = terraform.workspace == "prod" ? ["t3.large", "t3.xlarge"] : ["t3.micro", "t3.small"]
}

# Automated security group rules
locals {
  security_rules = {
    web = {
      ingress = [
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
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    database = {
      ingress = [
        {
          from_port       = 3306
          to_port         = 3306
          protocol        = "tcp"
          security_groups = [aws_security_group.web.id]
        }
      ]
      egress = []
    }
  }
}

# Dynamic security groups
resource "aws_security_group" "main" {
  for_each = local.security_rules
  
  name_prefix = "${terraform.workspace}-${each.key}-"
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }
  
  dynamic "egress" {
    for_each = each.value.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${terraform.workspace}-${each.key}-sg"
      Type = each.key
    }
  )
}

# Compliance validation
resource "null_resource" "compliance_check" {
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      # Check if all S3 buckets have encryption
      aws s3api list-buckets --query 'Buckets[].Name' --output text | \
      xargs -I {} aws s3api get-bucket-encryption --bucket {} || exit 1
      
      # Check if all EC2 instances have required tags
      aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,Tags]' --output table
    EOT
  }
}
```