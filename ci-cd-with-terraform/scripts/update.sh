#!/bin/bash

set -e

echo "=== Terraform Update Detection Script ==="

# Configuration
REPO_PATH="."
TERRAFORM_FILES=("*.tf" "*.tfvars" "*.hcl")
LAST_COMMIT_FILE=".last_terraform_commit"

# Function to check if terraform files changed
check_terraform_changes() {
    local last_commit=""
    
    # Read last processed commit
    if [[ -f "$LAST_COMMIT_FILE" ]]; then
        last_commit=$(cat "$LAST_COMMIT_FILE")
        echo "Last processed commit: $last_commit"
    else
        echo "No previous commit found, checking all files"
        last_commit="HEAD~1"
    fi
    
    # Get current commit
    current_commit=$(git rev-parse HEAD)
    echo "Current commit: $current_commit"
    
    # Check for changes in Terraform files
    changed_files=()
    for pattern in "${TERRAFORM_FILES[@]}"; do
        while IFS= read -r -d '' file; do
            if git diff --name-only "$last_commit" "$current_commit" | grep -q "$(basename "$file")"; then
                changed_files+=("$file")
            fi
        done < <(find . -name "$pattern" -print0)
    done
    
    if [[ ${#changed_files[@]} -gt 0 ]]; then
        echo "✓ Terraform files changed:"
        printf '%s\n' "${changed_files[@]}"
        return 0
    else
        echo "No Terraform files changed"
        return 1
    fi
}

# Function to trigger CI/CD pipeline
trigger_pipeline() {
    local environment=${1:-dev}
    
    echo "Triggering CI/CD pipeline for environment: $environment"
    
    # Method 1: GitHub Actions (if using GitHub)
    if command -v gh &> /dev/null; then
        echo "Triggering GitHub Actions workflow..."
        gh workflow run terraform-deploy.yml -f environment="$environment"
    fi
    
    # Method 2: Jenkins (if using Jenkins)
    if [[ -n "$JENKINS_URL" ]] && [[ -n "$JENKINS_TOKEN" ]]; then
        echo "Triggering Jenkins pipeline..."
        curl -X POST "$JENKINS_URL/job/terraform-pipeline/buildWithParameters" \
            --user "$JENKINS_USER:$JENKINS_TOKEN" \
            --data "ENVIRONMENT=$environment&ACTION=apply"
    fi
    
    # Method 3: Direct script execution (fallback)
    echo "Running validation and plan..."
    ./ci-cd/scripts/terraform-validate.sh
    ./ci-cd/scripts/terraform-plan.sh "$environment"
}

# Function to determine environment from branch
get_environment_from_branch() {
    local branch=$(git branch --show-current)
    
    case "$branch" in
        main|master)
            echo "prod"
            ;;
        staging|stage)
            echo "staging"
            ;;
        develop|dev)
            echo "dev"
            ;;
        *)
            echo "dev"
            ;;
    esac
}

# Main execution
main() {
    echo "Checking for Terraform file changes..."
    
    if check_terraform_changes; then
        # Determine environment
        environment=$(get_environment_from_branch)
        echo "Detected environment: $environment"
        
        # Trigger pipeline
        trigger_pipeline "$environment"
        
        # Update last commit
        git rev-parse HEAD > "$LAST_COMMIT_FILE"
        echo "Updated last commit reference"
        
    else
        echo "No changes detected, skipping pipeline"
    fi
}

# Run main function
main "$@"