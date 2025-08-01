#!/bin/bash

# Validation script for Terraform configuration
# This script helps validate the configuration before deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check AWS CLI configuration
check_aws_config() {
    print_info "Checking AWS CLI configuration..."
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI not configured or credentials not set"
        print_info "Run: aws configure"
        return 1
    fi
    
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    print_success "AWS CLI configured"
    print_info "Account: $AWS_ACCOUNT"
    print_info "Region: $AWS_REGION"
}

# Function to check AWS region AZs
check_availability_zones() {
    print_info "Checking availability zones in region..."
    
    AWS_REGION=$(aws configure get region)
    AZ_COUNT=$(aws ec2 describe-availability-zones --region $AWS_REGION --query 'AvailabilityZones[?State==`available`]' --output table | grep -c "available" || echo "0")
    
    if [ "$AZ_COUNT" -lt 2 ]; then
        print_error "Region $AWS_REGION has only $AZ_COUNT available AZs. At least 2 are required."
        return 1
    fi
    
    print_success "Region $AWS_REGION has $AZ_COUNT available AZs"
    
    # List the AZs
    print_info "Available AZs:"
    aws ec2 describe-availability-zones --region $AWS_REGION --query 'AvailabilityZones[?State==`available`].ZoneName' --output table
}

# Function to validate Terraform configuration
validate_terraform() {
    print_info "Validating Terraform configuration..."
    
    if ! terraform validate; then
        print_error "Terraform configuration validation failed"
        return 1
    fi
    
    print_success "Terraform configuration is valid"
}

# Function to check Terraform plan
check_terraform_plan() {
    local ENVIRONMENT=$1
    
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi
    
    print_info "Checking Terraform plan for $ENVIRONMENT environment..."
    
    if [ ! -f "environments/$ENVIRONMENT.tfvars" ]; then
        print_error "Environment file 'environments/$ENVIRONMENT.tfvars' not found!"
        return 1
    fi
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        terraform init
    fi
    
    # Create plan
    terraform plan -var-file="environments/$ENVIRONMENT.tfvars" -out=tfplan
    
    print_success "Terraform plan created successfully"
    print_info "To apply the plan, run: terraform apply tfplan"
}

# Function to show configuration summary
show_config_summary() {
    local ENVIRONMENT=$1
    
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi
    
    print_info "Configuration summary for $ENVIRONMENT environment:"
    
    if [ -f "environments/$ENVIRONMENT.tfvars" ]; then
        echo "Environment variables:"
        cat "environments/$ENVIRONMENT.tfvars" | grep -v "^#" | grep -v "^$" | sed 's/^/  /'
    fi
    
    echo ""
    print_info "Expected resources to be created:"
    echo "  - VPC with dynamic subnet configuration"
    echo "  - EKS cluster with managed node groups"
    echo "  - ECR repository for Docker images"
    echo "  - Application Load Balancer"
    echo "  - Kubernetes namespace, deployment, service, and ingress"
    echo "  - Horizontal Pod Autoscaler"
}

# Main function
main() {
    local COMMAND=$1
    local ENVIRONMENT=$2
    
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi
    
    case $COMMAND in
        "check")
            check_aws_config
            check_availability_zones
            validate_terraform
            ;;
        "plan")
            check_aws_config
            check_availability_zones
            validate_terraform
            check_terraform_plan "$ENVIRONMENT"
            ;;
        "summary")
            show_config_summary "$ENVIRONMENT"
            ;;
        *)
            echo "Usage: $0 {check|plan|summary} [environment]"
            echo ""
            echo "Commands:"
            echo "  check    - Check AWS configuration and validate Terraform"
            echo "  plan     - Create Terraform plan for deployment"
            echo "  summary  - Show configuration summary"
            echo ""
            echo "Environment: dev (default) or prod"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 plan dev"
            echo "  $0 plan prod"
            echo "  $0 summary prod"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 