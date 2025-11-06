#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}

echo "=== Terraform Destroy Script ==="
echo "Environment: $ENVIRONMENT"

# Check if environment is valid
valid_envs=("dev" "staging" "prod")
if [[ ! " ${valid_envs[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Valid options: ${valid_envs[*]}"
    exit 1
fi

# Production safety check
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo ""
    echo "🚨 DANGER: You are about to DESTROY PRODUCTION infrastructure!"
    echo "This action is IRREVERSIBLE and will delete all resources."
    echo ""
    read -p "Type 'DESTROY-PROD' to confirm production destruction: " confirm
    if [[ "$confirm" != "DESTROY-PROD" ]]; then
        echo "Destruction cancelled"
        exit 1
    fi
fi

# Initialize Terraform
echo "1. Initializing Terraform..."
terraform init

# Select workspace
echo "2. Selecting workspace: $ENVIRONMENT"
terraform workspace select $ENVIRONMENT

# Show what will be destroyed
echo "3. Showing resources to be destroyed:"
terraform plan -destroy -var-file="${ENVIRONMENT}.tfvars"

# Final confirmation
echo ""
echo "⚠️  The above resources will be DESTROYED!"
read -p "Type 'yes' to proceed with destruction: " final_confirm
if [[ "$final_confirm" != "yes" ]]; then
    echo "Destruction cancelled"
    exit 1
fi

# Destroy infrastructure
echo "4. Destroying infrastructure..."
terraform destroy -var-file="${ENVIRONMENT}.tfvars" -auto-approve

DESTROY_EXIT_CODE=$?

if [[ $DESTROY_EXIT_CODE -eq 0 ]]; then
    echo "✓ Terraform destroy completed successfully"
    
    # Save destroy log
    echo "5. Saving destroy log..."
    echo "Infrastructure destroyed at $(date)" > "destroy-log-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).txt"
    
else
    echo "✗ Terraform destroy failed with exit code: $DESTROY_EXIT_CODE"
    exit $DESTROY_EXIT_CODE
fi

echo "=== Destroy completed successfully ==="