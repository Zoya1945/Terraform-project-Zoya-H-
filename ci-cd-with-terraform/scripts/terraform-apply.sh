#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
PLAN_FILE="tfplan-${ENVIRONMENT}"

echo "=== Terraform Apply Script ==="
echo "Environment: $ENVIRONMENT"

# Check if environment is valid
valid_envs=("dev" "staging" "prod")
if [[ ! " ${valid_envs[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Valid options: ${valid_envs[*]}"
    exit 1
fi

# Check if plan file exists
if [[ ! -f "$PLAN_FILE" ]]; then
    echo "Error: Plan file $PLAN_FILE not found"
    echo "Please run terraform-plan.sh first"
    exit 1
fi

# Initialize Terraform
echo "1. Initializing Terraform..."
terraform init

# Select workspace
echo "2. Selecting workspace: $ENVIRONMENT"
terraform workspace select $ENVIRONMENT

# Apply the plan
echo "3. Applying Terraform plan..."
echo "Plan file: $PLAN_FILE"

# Show what will be applied
echo "4. Reviewing changes to be applied:"
terraform show -no-color "$PLAN_FILE" | head -20

# Confirmation for production
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo ""
    echo "⚠️  WARNING: You are about to apply changes to PRODUCTION!"
    echo "Please review the plan carefully."
    echo ""
    read -p "Type 'yes' to continue with production deployment: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Apply changes
echo "5. Applying changes..."
terraform apply "$PLAN_FILE"

APPLY_EXIT_CODE=$?

if [[ $APPLY_EXIT_CODE -eq 0 ]]; then
    echo "✓ Terraform apply completed successfully"
    
    # Show outputs
    echo "6. Terraform outputs:"
    terraform output
    
    # Save apply log
    echo "7. Saving apply log..."
    terraform show > "apply-result-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).txt"
    
else
    echo "✗ Terraform apply failed with exit code: $APPLY_EXIT_CODE"
    exit $APPLY_EXIT_CODE
fi

echo "=== Apply completed successfully ==="