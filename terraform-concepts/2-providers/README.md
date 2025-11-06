# Terraform Providers - Complete Guide

## What are Terraform Providers?

Terraform providers are plugins that enable Terraform to interact with cloud platforms, SaaS providers, and other APIs. They translate Terraform configuration into API calls to manage resources.

## Provider Architecture


Terraform Core
     ↓
Provider Plugin
     ↓
API Calls
     ↓
Cloud/Service Provider


## Provider Types

### 1. **Official Providers**
Maintained by HashiCorp
- `hashicorp/aws`
- `hashicorp/azurerm`
- `hashicorp/google`
- `hashicorp/kubernetes`

### 2. **Partner Providers**
Maintained by technology partners
- `datadog/datadog`
- `newrelic/newrelic`
- `mongodb/mongodbatlas`


### 3. **Community Providers**
Maintained by community
- `kreuzwerker/docker`
- `cloudflare/cloudflare`
- `digitalocean/digitalocean`

## Provider Configuration

### Basic Provider Block

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}


### Multiple Provider Configurations

# Default AWS provider
provider "aws" {
  region = "us-west-2"
}

# Aliased AWS provider for different region
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

# Use aliased provider
resource "aws_instance" "east_instance" {
  provider = aws.east
  
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}


## Major Cloud Providers

### 1. AWS Provider

#### Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key  # Not recommended
  secret_key = var.aws_secret_key  # Not recommended
  
  # Better: Use AWS CLI, IAM roles, or environment variables
  profile = "default"
  
  # Assume role
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
  
  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}


#### Common Resources

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-terraform-bucket"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}


### 2. Azure Provider

#### Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#### Common Resources

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform"
  location = "East US"
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "web" {
  name                = "web-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  
  admin_username = "adminuser"
  
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}


### 3. Google Cloud Provider

#### Configuration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  
  credentials = file("path/to/service-account.json")
}


#### Common Resources

# Compute Instance
resource "google_compute_instance" "web" {
  name         = "web-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    
    access_config {
      // Ephemeral public IP
    }
  }
}

# Storage Bucket
resource "google_storage_bucket" "data" {
  name     = "my-terraform-bucket"
  location = "US"
}


## Specialized Providers

### 1. Kubernetes Provider

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
  }
  
  spec {
    replicas = 3
    
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      
      spec {
        container {
          image = "nginx:1.21"
          name  = "nginx"
          
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
```

### 2. Docker Provider
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "nginx-container"
  
  ports {
    internal = 80
    external = 8080
  }
}

### 3. Helm Provider
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.0.1"
  
  values = [
    file("${path.module}/values.yaml")
  ]
}


## Provider Authentication

### 1. Environment Variables

# AWS
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Azure
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Google Cloud
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
export GOOGLE_PROJECT="your-project-id"


### 2. Configuration Files

# AWS - Use AWS CLI profiles
provider "aws" {
  profile = "production"
  region  = "us-west-2"
}

# Use shared credentials file
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "production"
}


### 3. IAM Roles (Recommended for AWS)

provider "aws" {
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformRole"
    session_name = "terraform-session"
  }
}


## Provider Versioning

### Version Constraints

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"      # >= 5.0, < 6.0
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"  # Explicit range
    }
    
    google = {
      source  = "hashicorp/google"
      version = "= 4.47.0"    # Exact version
    }
  }
}


### Version Operators
- `=` : Exact version
- `!=` : Not equal to version
- `>` : Greater than version
- `>=` : Greater than or equal to version
- `<` : Less than version
- `<=` : Less than or equal to version
- `~>` : Pessimistic constraint

## Provider Configuration Best Practices

### 1. Use Version Constraints

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


### 2. Avoid Hardcoded Credentials

# ❌ Bad
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# ✅ Good
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


### 3. Use Default Tags

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}


### 4. Provider Aliases for Multi-Region

provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

# Cross-region replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.us_west
  
  # Configuration...
}


## Custom Providers

### Creating a Custom Provider

// main.go
package main

import (
    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
    "github.com/mycompany/terraform-provider-myservice/myservice"
)

func main() {
    plugin.Serve(&plugin.ServeOpts{
        ProviderFunc: myservice.Provider,
    })
}


### Provider Schema

func Provider() *schema.Provider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "api_key": {
                Type:        schema.TypeString,
                Required:    true,
                Sensitive:   true,
                Description: "API key for authentication",
            },
        },
        ResourcesMap: map[string]*schema.Resource{
            "myservice_resource": resourceMyService(),
        },
        ConfigureFunc: providerConfigure,
    }
}


## Provider Registry

### Terraform Registry
- **URL**: https://registry.terraform.io/
- **Official source** for providers
- **Documentation** and examples
- **Version history**

### Private Registry

terraform {
  required_providers {
    mycompany = {
      source  = "registry.mycompany.com/mycompany/myservice"
      version = "~> 1.0"
    }
  }
}


## Troubleshooting Providers

### Common Issues

#### 1. Provider Not Found

# Error
Error: Failed to query available provider packages

# Solution
terraform init


#### 2. Version Conflicts

# Error
Error: Incompatible provider version

# Solution - Update version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Update version
    }
  }
}


#### 3. Authentication Issues

# Error
Error: NoCredentialProviders

# Solution - Set up authentication
aws configure
# or
export AWS_PROFILE=myprofile


### Debug Provider Issues

# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PROVIDER=DEBUG

terraform plan


## Conclusion

Terraform providers are the bridge between Terraform and external services. Understanding how to configure, version, and authenticate providers is crucial for successful infrastructure management. Always use version constraints, avoid hardcoded credentials, and leverage provider-specific features like default tags for better resource management.