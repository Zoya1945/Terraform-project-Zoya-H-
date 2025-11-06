#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
PLAN_FILE="tfplan-${ENVIRONMENT}"

echo "=== Terraform Plan Script ==="
echo "Environment: $ENVIRONMENT"

# Check if environment is valid
valid_envs=("dev" "staging" "prod")
if [[ ! " ${valid_envs[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment. Valid options: ${valid_envs[*]}"
    exit 1
fi

# Initialize Terraform
echo "1. Initializing Terraform..."
terraform init

# Select or create workspace
echo "2. Setting up workspace: $ENVIRONMENT"
terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT

# Refresh state
echo "3. Refreshing Terraform state..."
terraform refresh -var-file="${ENVIRONMENT}.tfvars"

# Generate plan
echo "4. Generating Terraform plan..."
terraform plan \
    -var-file="${ENVIRONMENT}.tfvars" \
    -out="$PLAN_FILE" \
    -detailed-exitcode

PLAN_EXIT_CODE=$?

# Check plan results
case $PLAN_EXIT_CODE in
    0)
        echo "✓ No changes required"
        ;;
    1)
        echo "✗ Plan failed"
        exit 1
        ;;
    2)
        echo "✓ Plan generated with changes"
        echo "Plan file: $PLAN_FILE"
        
        # Show plan summary
        echo "5. Plan Summary:"
        terraform show -no-color "$PLAN_FILE" | head -50
        ;;
esac

# Save plan output for review
terraform show -no-color "$PLAN_FILE" > "plan-output-${ENVIRONMENT}.txt"

echo "=== Plan completed successfully ==="
echo "Plan file: $PLAN_FILE"
echo "Plan output: plan-output-${ENVIRONMENT}.txt"