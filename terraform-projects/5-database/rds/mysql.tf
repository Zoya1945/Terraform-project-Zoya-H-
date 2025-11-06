# MySQL RDS Configuration

# DB Subnet Group
resource "aws_db_subnet_group" "mysql" {
  name       = "${var.project_name}-mysql-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-subnet-group"
  })
}

# Parameter Group
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "${var.project_name}-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  tags = local.common_tags
}

# Option Group
resource "aws_db_option_group" "mysql" {
  name                     = "${var.project_name}-mysql-options"
  option_group_description = "MySQL option group"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = local.common_tags
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7

  tags = local.common_tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# MySQL RDS Instance
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  # Engine Configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.mysql_instance_class

  # Storage Configuration
  allocated_storage     = var.mysql_allocated_storage
  max_allocated_storage = var.mysql_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  # Database Configuration
  db_name  = var.mysql_database_name
  username = var.mysql_username
  password = var.mysql_password

  # Network Configuration
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  parameter_group_name   = aws_db_parameter_group.mysql.name
  option_group_name      = aws_db_option_group.mysql.name

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  delete_automated_backups = false

  # High Availability
  multi_az               = var.mysql_multi_az
  publicly_accessible    = false
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
  
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  # Security
  deletion_protection = var.deletion_protection
  skip_final_snapshot = !var.final_snapshot_enabled
  final_snapshot_identifier = var.final_snapshot_enabled ? "${var.project_name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Logging
  enabled_cloudwatch_logs_exports = ["error", "general", "slow_query"]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql"
    Engine = "MySQL"
  })

  lifecycle {
    ignore_changes = [password]
  }
}

# Enhanced Monitoring IAM Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Security Group for MySQL RDS
resource "aws_security_group" "rds_mysql" {
  name_prefix = "${var.project_name}-mysql-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for MySQL RDS"

  ingress {
    description = "MySQL from app tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}