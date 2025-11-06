# Terraform Complete Learning Repository

A comprehensive Terraform learning repository with practical examples, concepts, projects, Q&A, and CI/CD automation.

## 📁 Repository Structure

```
terraform/
├── terraform-basic/          # Basic Terraform examples and tutorials
├── terraform-concepts/       # Detailed concept explanations with examples
├── terraform-projects/       # Real-world project implementations
├── terraform-qa/            # Interview questions and scenarios
├── ci-cd-with-terraform/     # CI/CD pipeline automation
└── README.md                # This file
```

## 📚 Directory Overview

### **terraform-basic/** - Foundational Examples
- **aws-ec2/** - Simple EC2 instance deployment
- **aws-vpc/** - VPC creation and configuration
- **aws-s3/** - S3 bucket management
- **tf-variables/** - Variable usage and types
- **tf-modules/** - Module creation and usage
- **tf-backend/** - Remote state configuration

### **terraform-concepts/** - Learning Materials
- **1-iac-history/** - Infrastructure as Code evolution
- **3-terraform-basics/** - Core Terraform concepts
- **8-state-management/** - State file management
- **10-modules/** - Module development
- **15-workspaces/** - Multi-environment management

### **terraform-projects/** - Production-Ready Projects
- **1-ec2/** - Complete EC2 infrastructure with ASG, ALB
- **2-networking/** - Advanced networking with VPC, subnets, routing
- **6-eks/** - Kubernetes cluster deployment
- **7-lambda/** - Serverless infrastructure

### **terraform-qa/** - Interview Preparation
- **Most Asked Questions** - 10 scenario-based questions in README
- **Topic-wise Q&A** - Detailed questions for each concept
- **Troubleshooting Guide** - Common issues and solutions
- **Real-world Scenarios** - Production problem-solving

### **ci-cd-with-terraform/** - Automation & DevOps
- **Jenkins Pipeline** - Declarative pipeline with approval gates
- **GitHub Actions** - GitOps workflows with drift detection
- **Automation Scripts** - Validate, plan, apply, destroy scripts
- **Security Integration** - tfsec scanning and compliance

## 🚀 Quick Start

```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install terraform

# Basic commands
terraform init
terraform plan
terraform apply
terraform destroy
```

## 📖 Learning Path

1. **Start with Basics** - `terraform-basic/`
2. **Master Concepts** - `terraform-concepts/`
3. **Build Real Projects** - `terraform-projects/`
4. **Practice Interview Questions** - `terraform-qa/`
5. **Implement CI/CD** - `ci-cd-with-terraform/`

---

**Happy Learning! 🎉**

