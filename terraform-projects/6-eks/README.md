# Complete EKS Infrastructure Project

## Overview
Enterprise-grade Kubernetes cluster with security, monitoring, and scalability

## Components

### EKS Cluster
- EKS Control Plane (Multi-AZ)
- Kubernetes version management
- Cluster endpoint configuration
- Encryption at rest

### Node Groups
- Managed Node Groups
- Spot & On-Demand instances
- Auto Scaling Groups
- Launch Templates
- Taints & Labels

### Networking
- VPC with private/public subnets
- Security Groups
- Network Policies
- Load Balancer integration

### Security
- RBAC configuration
- Pod Security Standards
- Network Policies
- Secrets encryption
- IAM Roles for Service Accounts (IRSA)

### Add-ons
- AWS Load Balancer Controller
- EBS CSI Driver
- EFS CSI Driver
- CoreDNS
- kube-proxy
- VPC CNI

### Monitoring & Logging
- CloudWatch Container Insights
- Prometheus & Grafana
- Fluent Bit logging
- X-Ray tracing

### Storage
- EBS volumes
- EFS file systems
- Storage Classes

## Architecture
```
                    EKS Control Plane
                    (Multi-AZ Masters)
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                 Public Subnets                           │
    │            (Load Balancers & NAT GW)                     │
    └──────────────────────────────────────────────────────────┘
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                Private Subnets                           │
    │              (Worker Nodes)                             │
    │                                                         │
    │  ┌─────────────────────────────────────────────────┐  │
    │  │              Node Group 1                    │  │
    │  │         (General Purpose)                   │  │
    │  └─────────────────────────────────────────────────┘  │
    │                                                         │
    │  ┌─────────────────────────────────────────────────┐  │
    │  │              Node Group 2                    │  │
    │  │            (Spot Instances)                  │  │
    │  └─────────────────────────────────────────────────┘  │
    └──────────────────────────────────────────────────────────┘
                           |
              Add-ons & Monitoring
```

## File Structure
```
6-eks/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── cluster/
│   ├── cluster.tf         # EKS cluster
│   └── iam-roles.tf       # Cluster IAM roles
├── node-groups/
│   ├── managed-nodes.tf   # Managed node groups
│   ├── spot-nodes.tf      # Spot instance nodes
│   └── launch-template.tf # Launch templates
├── networking/
│   ├── vpc.tf             # VPC for EKS
│   └── security-groups.tf # Security groups
├── security/
│   ├── rbac.tf            # RBAC configuration
│   └── irsa.tf            # IAM Roles for Service Accounts
├── addons/
│   ├── core-addons.tf     # Core EKS add-ons
│   ├── aws-lb-controller.tf # Load Balancer Controller
│   └── csi-drivers.tf     # CSI drivers
├── monitoring/
│   ├── cloudwatch.tf      # Container Insights
│   └── prometheus.tf      # Prometheus setup
└── logging/
    └── fluent-bit.tf      # Logging configuration
```

## Features
- Production-ready EKS cluster
- Multi-AZ high availability
- Cost optimization with Spot instances
- Comprehensive monitoring
- Security best practices
- Auto scaling
- Storage integration

## Usage
```bash
cd projects/6-eks
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name eks-cluster

# Verify cluster
kubectl get nodes
```