# Complete Networking Infrastructure Project

## Overview
Enterprise-grade networking infrastructure with multi-tier architecture

## Components

### Core VPC
- Custom VPC with DNS resolution
- DHCP Options Sets
- VPC Flow Logs with S3/CloudWatch
- IPv6 support (optional)

### Subnets & Availability
- Public Subnets (Web Tier) - Multi-AZ
- Private Subnets (App Tier) - Multi-AZ  
- Database Subnets (DB Tier) - Multi-AZ
- Management Subnets - Multi-AZ

### Internet Connectivity
- Internet Gateway
- NAT Gateways (Multi-AZ for HA)
- Elastic IPs
- Egress-only Internet Gateway (IPv6)

### Routing & Traffic Control
- Route Tables (Public/Private/DB)
- Route Propagation
- Network ACLs (Stateless)
- Security Groups (Stateful)

### VPC Endpoints
- Gateway Endpoints (S3, DynamoDB)
- Interface Endpoints (EC2, SSM, Logs)
- Private DNS resolution

### Advanced Features
- VPC Peering (Cross-region/account)
- Transit Gateway integration
- Direct Connect Gateway
- Site-to-Site VPN

### Security & Monitoring
- VPC Flow Logs
- DNS Query Logging
- Network Insights
- Reachability Analyzer

## Architecture
```
                    Internet Gateway
                           |
    ┌─────────────────────────────────────────────────────┐
    │                  Public Subnets                     │
    │              (Web Tier - Multi-AZ)                  │
    └─────────────────────────────────────────────────────┘
                           |
                    NAT Gateways (HA)
                           |
    ┌─────────────────────────────────────────────────────┐
    │                 Private Subnets                     │
    │              (App Tier - Multi-AZ)                  │
    └─────────────────────────────────────────────────────┘
                           |
    ┌─────────────────────────────────────────────────────┐
    │                Database Subnets                     │
    │               (DB Tier - Multi-AZ)                  │
    └─────────────────────────────────────────────────────┘
                           |
              VPC Endpoints & Peering
```

## File Structure
```
2-networking/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── vpc/
│   ├── vpc.tf             # VPC & core resources
│   └── flow-logs.tf       # VPC Flow Logs
├── subnets/
│   ├── public.tf          # Public subnets
│   ├── private.tf         # Private subnets
│   └── database.tf        # Database subnets
├── routing/
│   ├── internet-gw.tf     # Internet Gateway
│   ├── nat-gw.tf          # NAT Gateways
│   └── route-tables.tf    # Route Tables
├── security/
│   ├── nacls.tf           # Network ACLs
│   └── security-groups.tf # Security Groups
├── endpoints/
│   ├── gateway.tf         # Gateway Endpoints
│   └── interface.tf       # Interface Endpoints
├── peering/
│   └── vpc-peering.tf     # VPC Peering
└── transit-gateway/
    └── tgw.tf             # Transit Gateway
```

## Features
- Multi-AZ high availability
- Cost-optimized NAT Gateway placement
- Comprehensive security controls
- VPC endpoints for AWS services
- Cross-region connectivity
- Monitoring & logging
- IPv6 ready architecture

## Usage
```bash
cd projects/2-networking
terraform init
terraform plan
terraform apply
```