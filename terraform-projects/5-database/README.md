# Complete Database Infrastructure Project

## Overview
Enterprise-grade database infrastructure with multiple database engines

## Components

### Relational Databases (RDS)
- MySQL/PostgreSQL Multi-AZ
- Aurora Serverless v2
- Read Replicas (Cross-region)
- Parameter Groups & Option Groups
- Performance Insights
- Enhanced Monitoring

### NoSQL Databases
- DynamoDB with Global Tables
- DynamoDB Streams
- Point-in-time Recovery
- Auto Scaling

### Caching Layer
- ElastiCache Redis Cluster
- ElastiCache Memcached
- Redis AUTH & Encryption

### Graph & Document DBs
- DocumentDB (MongoDB compatible)
- Neptune (Graph database)
- Backup & Restore

### Security & Networking
- VPC with Private Subnets
- Security Groups per tier
- Secrets Manager integration
- KMS encryption

### Backup & Recovery
- Automated backups
- Manual snapshots
- Cross-region backup
- Point-in-time recovery

### Monitoring & Performance
- CloudWatch metrics
- Performance Insights
- Slow query logs
- Database activity streams

## Architecture
```
                    Application Layer
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                  ElastiCache                             │
    │              (Redis/Memcached)                           │
    └──────────────────────────────────────────────────────────┘
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                    RDS Layer                             │
    │         MySQL/PostgreSQL/Aurora (Multi-AZ)               │
    │              + Read Replicas                             │
    └──────────────────────────────────────────────────────────┘
                           |
    ┌──────────────────────────────────────────────────────────┐
    │                  NoSQL Layer                             │
    │        DynamoDB + DocumentDB + Neptune                   │
    └──────────────────────────────────────────────────────────┘
                           |
              Backup & Monitoring Layer
```

## File Structure
```
5-database/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── rds/
│   ├── mysql.tf           # MySQL RDS
│   ├── postgresql.tf      # PostgreSQL RDS
│   ├── aurora.tf          # Aurora Serverless
│   └── read-replicas.tf   # Read Replicas
├── dynamodb/
│   ├── tables.tf          # DynamoDB Tables
│   ├── global-tables.tf   # Global Tables
│   └── streams.tf         # DynamoDB Streams
├── elasticache/
│   ├── redis.tf           # Redis Cluster
│   └── memcached.tf       # Memcached
├── documentdb/
│   └── cluster.tf         # DocumentDB
├── neptune/
│   └── cluster.tf         # Neptune Graph DB
├── backup/
│   ├── rds-backup.tf      # RDS Backup
│   └── cross-region.tf    # Cross-region backup
└── monitoring/
    ├── cloudwatch.tf      # Metrics & Alarms
    └── performance.tf     # Performance Insights
```

## Features
- Multi-engine database support
- High availability & disaster recovery
- Automated scaling
- Security best practices
- Performance optimization
- Cost optimization
- Comprehensive monitoring

## Usage
```bash
cd projects/5-database
terraform init
terraform apply
```