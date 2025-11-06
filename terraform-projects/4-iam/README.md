# Complete IAM Infrastructure Project

## Overview
Enterprise-grade Identity and Access Management with security best practices

## Components

### User Management
- IAM Users with MFA enforcement
- User Groups by department/role
- Access Keys & Console Access
- Password policies & rotation

### Role-Based Access
- Service Roles (EC2, Lambda, ECS)
- Cross-account roles
- SAML/OIDC Federation
- Instance Profiles

### Policy Management
- Custom IAM Policies
- Permission Boundaries
- Resource-based policies
- Policy versioning

### Security Features
- MFA enforcement
- Access Analyzer
- CloudTrail integration
- Credential rotation
- Least privilege access

### Service Integration
- AWS SSO integration
- Secrets Manager
- Parameter Store access
- KMS key policies

### Compliance & Auditing
- Access reviews
- Unused access cleanup
- Policy simulation
- Compliance reporting

## Architecture
```
                    Identity Providers
                    (SAML/OIDC/SSO)
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                    IAM Users                             │
    │              (Developers, Admins)                       │
    └──────────────────────────────────────────────────────────┘
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                   IAM Groups                             │
    │           (Department-based access)                     │
    └──────────────────────────────────────────────────────────┘
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                 Service Roles                           │
    │         (EC2, Lambda, ECS, EKS, etc.)                   │
    └──────────────────────────────────────────────────────────┘
                           |
              Cross-account & Federation
```

## File Structure
```
4-iam/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── users-groups/
│   ├── users.tf           # IAM Users
│   ├── groups.tf          # IAM Groups
│   └── memberships.tf     # Group memberships
├── roles/
│   ├── assume-roles.tf    # Assumable roles
│   └── instance-profiles.tf # EC2 instance profiles
├── policies/
│   ├── custom-policies.tf # Custom IAM policies
│   └── boundaries.tf      # Permission boundaries
├── service-roles/
│   ├── ec2-roles.tf       # EC2 service roles
│   ├── lambda-roles.tf    # Lambda execution roles
│   └── ecs-roles.tf       # ECS task roles
├── cross-account/
│   ├── cross-roles.tf     # Cross-account roles
│   └── federation.tf      # SAML/OIDC providers
└── security/
    ├── password-policy.tf # Password policies
    ├── mfa-policy.tf      # MFA enforcement
    └── access-analyzer.tf # Access Analyzer
```

## Features
- Least privilege access
- MFA enforcement
- Automated access reviews
- Cross-account access
- Service integration
- Compliance monitoring
- Security best practices

## Usage
```bash
cd projects/4-iam
terraform init
terraform apply
```