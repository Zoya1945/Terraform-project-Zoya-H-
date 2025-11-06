# Infrastructure as Code History - Scenarios

## Scenario 1: Legacy to IaC Migration

**Situation:** Your company has 200+ manually configured servers across multiple environments. Management wants to migrate to IaC.

**Challenge:** How would you approach this migration?

**Solution:**
1. **Assessment Phase**
   - Inventory existing infrastructure
   - Document current configurations
   - Identify dependencies and critical systems

2. **Strategy Development**
   - Choose IaC tool (Terraform recommended)
   - Define migration phases (dev → staging → prod)
   - Create rollback plans

3. **Implementation**
   ```hcl
   # Start with import existing resources
   terraform import aws_instance.web i-1234567890abcdef0
   
   # Gradually convert to code
   resource "aws_instance" "web" {
     ami           = "ami-12345678"
     instance_type = "t3.medium"
     # ... existing configuration
   }
   ```

4. **Validation**
   - Compare imported vs actual state
   - Test in non-production first
   - Gradual rollout with monitoring

## Scenario 2: Multi-Cloud IaC Strategy

**Situation:** Company uses AWS, Azure, and GCP. Need unified IaC approach.

**Challenge:** How to manage multi-cloud infrastructure efficiently?

**Solution:**
```hcl
# terraform/providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Separate modules per cloud
module "aws_infrastructure" {
  source = "./modules/aws"
  # AWS-specific variables
}

module "azure_infrastructure" {
  source = "./modules/azure"
  # Azure-specific variables
}
```

**Best Practices:**
- Use separate state files per cloud
- Standardize naming conventions
- Create cloud-agnostic modules where possible
- Implement cross-cloud networking carefully

## Scenario 3: IaC Governance Implementation

**Situation:** Multiple teams creating infrastructure without standards, causing security and cost issues.

**Challenge:** Implement governance without slowing down development.

**Solution:**
1. **Policy as Code**
   ```hcl
   # Sentinel policy example
   import "tfplan/v2" as tfplan
   
   # Ensure all EC2 instances have required tags
   required_tags = ["Environment", "Owner", "Project"]
   
   main = rule {
     all tfplan.resource_changes as _, rc {
       rc.type is "aws_instance" implies
         all required_tags as tag {
           rc.change.after.tags contains tag
         }
     }
   }
   ```

2. **Module Standards**
   - Create approved module library
   - Enforce module usage through CI/CD
   - Regular security scanning

3. **Workflow Enforcement**
   - Mandatory code reviews
   - Automated testing
   - Approval workflows for production

## Scenario 4: Disaster Recovery with IaC

**Situation:** Need to implement DR strategy using IaC for critical applications.

**Challenge:** Ensure infrastructure can be recreated quickly in different regions.

**Solution:**
```hcl
# variables.tf
variable "regions" {
  description = "Primary and DR regions"
  type = object({
    primary = string
    dr      = string
  })
  default = {
    primary = "us-east-1"
    dr      = "us-west-2"
  }
}

# main.tf
module "primary_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.primary
  }
  
  region      = var.regions.primary
  environment = "primary"
}

module "dr_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.dr
  }
  
  region      = var.regions.dr
  environment = "dr"
}
```

**DR Testing:**
- Automated DR environment provisioning
- Regular failover testing
- Data replication verification
- RTO/RPO monitoring