# IAM Users Configuration

# Developers
resource "aws_iam_user" "developers" {
  for_each = toset(var.developer_users)
  
  name = each.key
  path = "/developers/"
  
  force_destroy = true

  tags = merge(local.common_tags, {
    Department = "Engineering"
    Role       = "Developer"
  })
}

# DevOps Engineers
resource "aws_iam_user" "devops" {
  for_each = toset(var.devops_users)
  
  name = each.key
  path = "/devops/"
  
  force_destroy = true

  tags = merge(local.common_tags, {
    Department = "Engineering"
    Role       = "DevOps"
  })
}

# Data Scientists
resource "aws_iam_user" "data_scientists" {
  for_each = toset(var.data_science_users)
  
  name = each.key
  path = "/data-science/"
  
  force_destroy = true

  tags = merge(local.common_tags, {
    Department = "Data"
    Role       = "DataScientist"
  })
}

# Administrators
resource "aws_iam_user" "admins" {
  for_each = toset(var.admin_users)
  
  name = each.key
  path = "/admins/"
  
  force_destroy = true

  tags = merge(local.common_tags, {
    Department = "IT"
    Role       = "Administrator"
  })
}

# Console Access for Users
resource "aws_iam_user_login_profile" "developers" {
  for_each = aws_iam_user.developers
  
  user    = each.value.name
  password_reset_required = true
  
  lifecycle {
    ignore_changes = [password_reset_required]
  }
}

resource "aws_iam_user_login_profile" "devops" {
  for_each = aws_iam_user.devops
  
  user    = each.value.name
  password_reset_required = true
  
  lifecycle {
    ignore_changes = [password_reset_required]
  }
}

# Access Keys for Programmatic Access (Optional)
resource "aws_iam_access_key" "developers_keys" {
  for_each = var.create_access_keys ? aws_iam_user.developers : {}
  
  user = each.value.name
}

# MFA Devices (Virtual MFA)
resource "aws_iam_virtual_mfa_device" "developers_mfa" {
  for_each = aws_iam_user.developers
  
  virtual_mfa_device_name = "${each.value.name}-mfa"
  path                   = each.value.path

  tags = local.common_tags
}

# User Policies - Force MFA
resource "aws_iam_user_policy" "force_mfa" {
  for_each = merge(
    aws_iam_user.developers,
    aws_iam_user.devops,
    aws_iam_user.data_scientists,
    aws_iam_user.admins
  )
  
  name = "ForceMFA"
  user = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnPasswords"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = [
          "arn:aws:iam::*:mfa/$${aws:username}",
          "arn:aws:iam::*:user/$${aws:username}"
        ]
      },
      {
        Sid    = "DenyAllExceptUnlessSignedInWithMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}