#!/bin/bash

###########################################
# Deployment script for Imply Infrastructure
# 
# This script collects user inputs and deploys
# an EC2 instance with Imply Manager and Agent
# 
# Author: Solutions Architect Team
# Version: 1.2
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate AWS region
validate_region() {
    local region=$1
    if aws ec2 describe-regions --region-names "$region" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to validate instance type
validate_instance_type() {
    local instance_type=$1
    if aws ec2 describe-instance-types --instance-types "$instance_type" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get host IP
get_host_ip() {
    curl -s http://checkip.amazonaws.com
}

# Function to validate email
validate_email() {
    local email=$1
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to handle key pair selection
handle_key_pair() {
    local region=$1
    local keys_dir="../keys"
    local selected_key=""
    
    # Create keys directory if it doesn't exist
    mkdir -p "$keys_dir"
    
    # List existing key pairs
    # print_message "$GREEN" "Available key pairs in region $region:"
    # aws ec2 describe-key-pairs --region "$region" --query 'KeyPairs[*].KeyName' --output table

    # Ask for key pair name
    while true; do
        read -p "Enter the name of the key pair to use: " selected_key
        
        # Verify key pair exists
        if aws ec2 describe-key-pairs --key-names "$selected_key" --region "$region" >/dev/null 2>&1; then
            break
        else
            print_message "$RED" "Error: Key pair '$selected_key' not found in region $region. Please try again."
        fi
    done
    
    # Check if private key file exists locally
    if [ ! -f "$keys_dir/$selected_key.pem" ]; then
        print_message "$YELLOW" "Warning: Private key file not found at $keys_dir/$selected_key.pem"
        print_message "$YELLOW" "Make sure you have the private key file to access the instance later"
    else
        # Ensure correct permissions if key exists
        chmod 400 "$keys_dir/$selected_key.pem"
    fi
    
    echo "$selected_key"
}

# Check for required tools
for tool in aws terraform curl jq; do
    if ! command_exists $tool; then
        print_message "$RED" "Error: $tool is not installed. Please install it and try again."
        exit 1
    fi
done

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_message "$RED" "Error: AWS credentials not configured. Please configure them and try again."
    exit 1
fi

# Collect user inputs
print_message "$GREEN" "Welcome to Imply Infrastructure Deployment Script"
echo "----------------------------------------"

# Region selection
while true; do
    read -p "Enter AWS region (e.g., us-east-1): " REGION
    if validate_region "$REGION"; then
        break
    else
        print_message "$RED" "Invalid region. Please try again."
    fi
done

# Key pair selection
KEY_NAME=$(handle_key_pair "$REGION")
print_message "$GREEN" "Using key pair: $KEY_NAME"

# Instance type selection
while true; do
    read -p "Enter instance type (default: t2.xlarge): " INSTANCE_TYPE
    INSTANCE_TYPE=${INSTANCE_TYPE:-t2.xlarge}
    if validate_instance_type "$INSTANCE_TYPE"; then
        break
    else
        print_message "$RED" "Invalid instance type. Please try again."
    fi
done

# VPC and Security Group Information
echo "Available VPCs in region $REGION:"
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

read -p "Enter VPC ID: " VPC_ID

echo "Available Security Groups in VPC $VPC_ID:"
aws ec2 describe-security-groups --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[*].[GroupId,GroupName]' --output table

read -p "Enter Security Group ID: " SG_ID

# Storage size
read -p "Enter root volume size in GB (default: 50): " STORAGE_SIZE
STORAGE_SIZE=${STORAGE_SIZE:-50}

# Collect tags
read -p "Enter EC2 instance name: " INSTANCE_NAME
while true; do
    read -p "Enter contact email: " CONTACT_EMAIL
    if validate_email "$CONTACT_EMAIL"; then
        break
    else
        print_message "$RED" "Invalid email format. Please try again."
    fi
done
read -p "Enter application name: " APP_NAME
read -p "Enter team name: " TEAM_NAME

# Get host IP
HOST_IP=$(get_host_ip)
if [ -z "$HOST_IP" ]; then
    print_message "$RED" "Error: Could not determine host IP address."
    exit 1
fi

# Create terraform.tfvars file
cat > terraform.tfvars << EOF
aws_region = "${REGION}"
instance_type = "${INSTANCE_TYPE}"
vpc_id = "${VPC_ID}"
security_group_id = "${SG_ID}"
storage_size = ${STORAGE_SIZE}
host_ip = "${HOST_IP}"
key_name = "${KEY_NAME}"

tags = {
    Name = "${INSTANCE_NAME}"
    contact = "${CONTACT_EMAIL}"
    application = "${APP_NAME}"
    team = "${TEAM_NAME}"
    managed_by = "terraform"
}
EOF

# Initialize and apply Terraform
print_message "$GREEN" "Initializing Terraform..."
terraform init

print_message "$YELLOW" "Planning Terraform changes..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "$GREEN" "Applying Terraform configuration..."
    terraform apply tfplan

    # Get the Public IP of the instance
    PUBLIC_IP=$(terraform output -raw public_ip)

    print_message "$YELLOW" "Waiting for instance to be ready..."
    sleep 60

    print_message "$GREEN" "Deployment complete!"
    echo "Instance Public IP: ${PUBLIC_IP}"
    echo "VPC ID: ${VPC_ID}"
    echo "Security Group ID: ${SG_ID}"
    echo "Key Pair: ${KEY_NAME}"
    echo "SSH Command: ssh -i ../keys/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
else
    print_message "$YELLOW" "Deployment cancelled."
    exit 0
fi