# Monitoring Project

## Overview
Complete monitoring setup with CloudWatch, SNS, and alarms

## Components
- CloudWatch Dashboards
- CloudWatch Alarms
- SNS Topics & Subscriptions
- Log Groups
- Custom Metrics

## Architecture
```
CloudWatch Metrics
    |
CloudWatch Alarms
    |
SNS Notifications
    |
Email/SMS Alerts
```

## Usage
```bash
cd projects/8-monitoring
terraform init
terraform apply
```