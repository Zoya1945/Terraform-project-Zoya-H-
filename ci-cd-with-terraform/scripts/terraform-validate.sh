#!/bin/bash

set -e

echo "=== Terraform Validation Script ==="

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    exit 1
fi

# Format check
echo "1. Running terraform fmt check..."
if ! terraform fmt -check -recursive .; then
    echo "Error: Terraform files are not properly formatted"
    echo "Run 'terraform fmt -recursive .' to fix formatting"
    exit 1
fi
echo "✓ Terraform formatting check passed"

# Initialize Terraform
echo "2. Initializing Terraform..."
terraform init -backend=false

# Validate configuration
echo "3. Validating Terraform configuration..."
if ! terraform validate; then
    echo "Error: Terraform validation failed"
    exit 1
fi
echo "✓ Terraform validation passed"

# Check for required files
echo "4. Checking for required files..."
required_files=("main.tf" "variables.tf" "outputs.tf")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Warning: $file not found"
    else
        echo "✓ Found $file"
    fi
done

# Lint with tflint if available
if command -v tflint &> /dev/null; then
    echo "5. Running tflint..."
    tflint --init
    tflint
    echo "✓ TFLint check passed"
else
    echo "5. TFLint not available, skipping..."
fi

echo "=== Validation completed successfully ==="