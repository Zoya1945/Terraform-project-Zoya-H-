# Complete Lambda Serverless Project

## Overview
Enterprise serverless application with multiple functions, API Gateway, and integrations

## Components

### Lambda Functions
- CRUD API functions
- Event processing functions
- Scheduled functions
- Image processing
- Data transformation

### API Gateway
- REST API with multiple resources
- WebSocket API for real-time
- Custom authorizers
- Request/Response validation
- Throttling & caching

### Event Sources
- S3 triggers
- DynamoDB Streams
- SQS queues
- EventBridge rules
- CloudWatch Events

### Storage & Database
- DynamoDB tables
- S3 buckets
- ElastiCache integration
- RDS Proxy connections

### Security
- IAM roles & policies
- VPC configuration
- Secrets Manager
- KMS encryption

### Monitoring & Logging
- CloudWatch Logs
- X-Ray tracing
- Custom metrics
- Alarms & notifications

### Performance
- Lambda Layers
- Provisioned Concurrency
- Dead Letter Queues
- Retry configurations

## Architecture
```
                    API Gateway
                 (REST + WebSocket)
                        |
    ┌──────────────────────────────────────────────────────────┐
    │                  Lambda Functions                        │
    │                                                        │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
    │  │  CRUD API   │  │ Processing │  │ Scheduled  │  │
    │  │ Functions  │  │ Functions  │  │ Functions  │  │
    │  └─────────────┘  └─────────────┘  └─────────────┘  │
    └──────────────────────────────────────────────────────────┘
                        |
    ┌──────────────────────────────────────────────────────────┐
    │                Event Sources                            │
    │        S3, DynamoDB, SQS, EventBridge                   │
    └──────────────────────────────────────────────────────────┘
                        |
    ┌──────────────────────────────────────────────────────────┐
    │              Storage & Database                         │
    │        DynamoDB, S3, ElastiCache, RDS                   │
    └──────────────────────────────────────────────────────────┘
```

## File Structure
```
7-lambda/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── functions/
│   ├── crud-api.tf        # CRUD API functions
│   ├── processors.tf      # Event processors
│   ├── scheduled.tf       # Scheduled functions
│   └── authorizers.tf     # Custom authorizers
├── api-gateway/
│   ├── rest-api.tf        # REST API Gateway
│   ├── websocket.tf       # WebSocket API
│   └── deployment.tf      # API deployments
├── triggers/
│   ├── s3-triggers.tf     # S3 event triggers
│   ├── dynamodb-streams.tf # DynamoDB triggers
│   └── eventbridge.tf     # EventBridge rules
├── layers/
│   └── lambda-layers.tf   # Lambda layers
├── monitoring/
│   ├── cloudwatch.tf      # Logs & metrics
│   └── xray.tf            # X-Ray tracing
└── security/
    ├── iam-roles.tf       # IAM roles
    └── vpc-config.tf      # VPC configuration
```

## Functions

### CRUD API
- **create-item**: POST /items
- **get-item**: GET /items/{id}
- **list-items**: GET /items
- **update-item**: PUT /items/{id}
- **delete-item**: DELETE /items/{id}

### Event Processing
- **image-processor**: S3 image uploads
- **data-transformer**: DynamoDB streams
- **notification-sender**: SQS messages

### Scheduled Tasks
- **cleanup-job**: Daily cleanup
- **report-generator**: Weekly reports
- **health-checker**: Monitoring

## Features
- Serverless architecture
- Auto scaling
- Pay-per-use pricing
- Event-driven processing
- Real-time capabilities
- Comprehensive monitoring
- Security best practices

## Usage
```bash
cd projects/7-lambda
terraform init
terraform apply

# Test API
curl https://api-id.execute-api.region.amazonaws.com/prod/items
```