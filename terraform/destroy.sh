#!/bin/bash

###########################################
# Cleanup script for Imply Infrastructure
# 
# This script destroys the EC2 instance and
# associated resources while preserving the
# VPC and Security Group
# 
# Author: Solutions Architect Team
# Version: 1.0
###########################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if terraform is installed
if ! command -v terraform >/dev/null 2>&1; then
    print_message "$RED" "Error: terraform is not installed. Please install it and try again."
    exit 1
fi

# Get instance information before destruction
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
if [ ! -z "$INSTANCE_ID" ]; then
    print_message "$YELLOW" "Found instance: $INSTANCE_ID"
fi

# Confirm destruction
print_message "$RED" "WARNING: This will destroy the EC2 instance and associated resources."
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_message "$YELLOW" "Destruction cancelled."
    exit 0
fi

# Run Terraform destroy
print_message "$YELLOW" "Destroying infrastructure..."
terraform destroy -target=aws_instance.ec2_instance -auto-approve

print_message "$GREEN" "Destruction complete!"