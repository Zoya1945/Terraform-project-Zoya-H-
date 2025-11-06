# Complete EC2 Infrastructure Project

## Overview
Comprehensive EC2 infrastructure with everything needed for production

## Components

### VPC & Networking
- Custom VPC with DNS support
- Public & Private Subnets (Multi-AZ)
- Internet Gateway & NAT Gateways
- Route Tables & Associations
- VPC Flow Logs

### Security
- Security Groups (Web, App, DB tiers)
- Network ACLs
- Key Pairs
- IAM Roles & Instance Profiles

### Compute
- Launch Templates with user data
- Auto Scaling Groups
- Spot & On-Demand instances
- Multiple instance types

### Load Balancing
- Application Load Balancer
- Network Load Balancer
- Target Groups with health checks
- SSL/TLS certificates

### Storage
- EBS volumes (gp3, io1)
- EBS snapshots
- Instance store optimization

### Monitoring & Logging
- CloudWatch metrics & alarms
- CloudWatch Logs
- SNS notifications
- Custom dashboards

### Backup & Recovery
- EBS snapshot policies
- AMI creation
- Cross-region backup

## Architecture
```
Internet Gateway
    |
Application/Network Load Balancer
    |
Auto Scaling Groups (Multi-AZ)
    |-- Web Tier (Public Subnets)
    |-- App Tier (Private Subnets)
    |-- DB Tier (Private Subnets)
    |
NAT Gateways
    |
VPC Endpoints
```

## File Structure
```
1-ec2/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── vpc/
│   ├── vpc.tf             # VPC resources
│   └── subnets.tf         # Subnets & routing
├── security-groups/
│   ├── web-sg.tf          # Web tier security
│   └── app-sg.tf          # App tier security
├── load-balancer/
│   ├── alb.tf             # Application LB
│   └── nlb.tf             # Network LB
├── auto-scaling/
│   ├── launch-template.tf # Launch templates
│   └── asg.tf             # Auto scaling groups
├── monitoring/
│   ├── cloudwatch.tf      # Metrics & alarms
│   └── sns.tf             # Notifications
└── backup/
    └── snapshots.tf       # Backup policies
```

## Usage
```bash
cd projects/1-ec2
terraform init
terraform plan
terraform apply
```

## Features
- Multi-AZ deployment
- Auto scaling based on metrics
- SSL termination
- Health checks
- Monitoring & alerting
- Automated backups
- Cost optimization with Spot instances
- Security best practices