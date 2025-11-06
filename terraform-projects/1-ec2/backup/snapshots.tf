# Data Lifecycle Manager for EBS Snapshots
resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  description        = "EBS snapshot policy for ${var.project_name}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types   = ["VOLUME"]
    target_tags = {
      Project = var.project_name
    }

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = merge(local.common_tags, {
        SnapshotCreator = "DLM"
      })

      copy_tags = true
    }
  }

  tags = local.common_tags
}

# IAM Role for DLM
resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "${var.project_name}-dlm-lifecycle-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name = "${var.project_name}-dlm-lifecycle-policy"
  role = aws_iam_role.dlm_lifecycle_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:ModifySnapshotAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# AMI Creation Policy
resource "aws_dlm_lifecycle_policy" "ami_creation" {
  description        = "AMI creation policy for ${var.project_name}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types   = ["INSTANCE"]
    target_tags = {
      Project = var.project_name
    }

    schedule {
      name = "Weekly AMI creation"

      create_rule {
        interval      = 7
        interval_unit = "DAYS"
        times         = ["02:00"]
      }

      retain_rule {
        count = 4
      }

      tags_to_add = merge(local.common_tags, {
        AMICreator = "DLM"
      })

      copy_tags = true
    }
  }

  tags = local.common_tags
}

# Backup Vault for AWS Backup
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = local.common_tags
}

# KMS Key for Backup Encryption
resource "aws_kms_key" "backup" {
  description             = "KMS key for ${var.project_name} backups"
  deletion_window_in_days = 7

  tags = local.common_tags
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.project_name}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

# Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    recovery_point_tags = local.common_tags
  }

  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * SUN *)"

    lifecycle {
      cold_storage_after = 90
      delete_after       = 365
    }

    recovery_point_tags = merge(local.common_tags, {
      BackupType = "Weekly"
    })
  }

  tags = local.common_tags
}

# Backup Selection
resource "aws_backup_selection" "ec2_backup" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.project_name}-ec2-backup"
  plan_id      = aws_backup_plan.main.id

  resources = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Project"
      value = var.project_name
    }
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}