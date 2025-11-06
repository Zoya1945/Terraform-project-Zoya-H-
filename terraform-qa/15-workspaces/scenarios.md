# Terraform Workspaces - Scenarios

## Scenario 1: Multi-Environment Deployment

**Situation:** Deploy same application to dev, staging, and prod with different configurations.

**Solution:**
```hcl
# main.tf
locals {
  env_config = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
      db_size      = "db.t3.micro"
    }
    staging = {
      instance_type = "t3.small"
      min_size     = 2
      max_size     = 4
      db_size      = "db.t3.small"
    }
    prod = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
      db_size      = "db.t3.large"
    }
  }
  
  config = local.env_config[terraform.workspace]
}

resource "aws_launch_template" "app" {
  name_prefix   = "${terraform.workspace}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.config.instance_type
}

resource "aws_autoscaling_group" "app" {
  name                = "${terraform.workspace}-app-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  
  min_size         = local.config.min_size
  max_size         = local.config.max_size
  desired_capacity = local.config.min_size
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

**Deployment:**
```bash
# Deploy to dev
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# Deploy to staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

# Deploy to prod
terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

## Scenario 2: Workspace State Management Issue

**Problem:** Team accidentally deployed prod resources in dev workspace.

**Solution:**
```bash
# 1. Check current workspace
terraform workspace show

# 2. List all resources in wrong workspace
terraform state list

# 3. Move resources to correct workspace
terraform workspace select prod
terraform import aws_instance.web i-1234567890abcdef0

# 4. Remove from wrong workspace
terraform workspace select dev
terraform state rm aws_instance.web

# 5. Validate both workspaces
terraform workspace select dev
terraform plan

terraform workspace select prod
terraform plan
```

## Scenario 3: CI/CD Pipeline with Workspaces

**Situation:** Implement automated deployment pipeline using workspaces.

**Solution:**
```yaml
# .github/workflows/terraform.yml
name: Terraform Multi-Environment
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        workspace: [dev, staging, prod]
        include:
          - workspace: dev
            branch: develop
          - workspace: staging
            branch: main
          - workspace: prod
            branch: main
            
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
        
    - name: Terraform Init
      run: terraform init
      
    - name: Select/Create Workspace
      run: |
        terraform workspace select ${{ matrix.workspace }} || \
        terraform workspace new ${{ matrix.workspace }}
        
    - name: Terraform Plan
      run: terraform plan -var-file="${{ matrix.workspace }}.tfvars" -out=tfplan
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/${{ matrix.branch }}'
      run: terraform apply -auto-approve tfplan
```