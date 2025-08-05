#!/bin/bash

# Cleanup script for JavaScript 2D Game EKS Infrastructure
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if environment file is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <environment> [--force]"
    print_error "Example: $0 dev"
    print_error "Example: $0 dev --force (to skip confirmation)"
    exit 1
fi

ENVIRONMENT=$1
FORCE=false

if [ "$2" = "--force" ]; then
    FORCE=true
fi

TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "Environment file $TFVARS_FILE not found!"
    exit 1
fi

print_status "Starting cleanup for environment: $ENVIRONMENT"

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

print_status "AWS credentials verified"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Get cluster information before destruction
print_step "Getting cluster information..."
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "javascript-2d-game-${ENVIRONMENT}")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

print_status "EKS Cluster Name: $CLUSTER_NAME"
print_status "AWS Region: $AWS_REGION"

# Ask for confirmation unless --force is used
if [ "$FORCE" = false ]; then
    echo
    print_warning "This will destroy ALL infrastructure for environment: $ENVIRONMENT"
    print_warning "This includes:"
    echo "  - EKS Cluster: $CLUSTER_NAME"
    echo "  - VPC and all networking resources"
    echo "  - ECR Repository"
    echo "  - All IAM roles and policies"
    echo "  - Load balancers and related resources"
    echo
    read -p "Are you absolutely sure you want to proceed? (type 'yes' to confirm): " -r response
    if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled by user"
        exit 0
    fi
fi

# Initialize Terraform if needed
print_step "Initializing Terraform..."
terraform init

# Plan the destruction
print_step "Planning destruction..."
terraform plan -var-file="$TFVARS_FILE" -destroy -out=destroy-plan

# Apply the destruction
print_step "Destroying infrastructure..."
terraform apply destroy-plan

# Clean up plan file
rm -f destroy-plan

print_status "Infrastructure cleanup completed successfully!"

print_status "Cleanup summary:"
echo "  - EKS Cluster: $CLUSTER_NAME (DESTROYED)"
echo "  - VPC and networking resources (DESTROYED)"
echo "  - ECR Repository (DESTROYED)"
echo "  - IAM roles and policies (DESTROYED)"
echo "  - Load balancers (DESTROYED)"

print_status "All resources have been cleaned up!" 