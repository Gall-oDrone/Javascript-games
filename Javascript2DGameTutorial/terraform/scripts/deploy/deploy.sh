#!/bin/bash

# Deployment script for JavaScript 2D Game
# Following AWS Blueprints best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TERRAFORM_DIR="$PROJECT_ROOT"

# Default values
ENVIRONMENT="dev"
ACTION="apply"
AUTO_APPROVE=false
PLAN_ONLY=false

# Function to print colored output
print_status() {
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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy JavaScript 2D Game infrastructure using Terraform

OPTIONS:
    -e, --environment ENV    Environment to deploy (dev, staging, prod) [default: dev]
    -a, --action ACTION      Terraform action (plan, apply, destroy) [default: apply]
    -p, --plan-only          Only run terraform plan, don't apply
    -y, --auto-approve       Auto-approve terraform changes
    -h, --help               Show this help message

EXAMPLES:
    $0 -e dev -a plan        # Plan dev environment
    $0 -e prod -a apply -y   # Apply prod environment with auto-approve
    $0 -e dev -a destroy     # Destroy dev environment

EOF
}

# Function to validate environment
validate_environment() {
    local env="$1"
    case "$env" in
        dev|staging|prod)
            return 0
            ;;
        *)
            print_error "Invalid environment: $env. Must be one of: dev, staging, prod"
            exit 1
            ;;
    esac
}

# Function to validate action
validate_action() {
    local action="$1"
    case "$action" in
        plan|apply|destroy)
            return 0
            ;;
        *)
            print_error "Invalid action: $action. Must be one of: plan, apply, destroy"
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if aws CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. Some post-deployment checks may fail."
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to initialize Terraform
init_terraform() {
    local env="$1"
    local env_dir="$TERRAFORM_DIR/environments/$env"
    
    print_status "Initializing Terraform for $env environment..."
    
    if [ ! -d "$env_dir" ]; then
        print_error "Environment directory not found: $env_dir"
        exit 1
    fi
    
    cd "$env_dir"
    
    # Initialize Terraform
    terraform init -upgrade
    
    print_success "Terraform initialized successfully"
}

# Function to run Terraform plan
run_terraform_plan() {
    local env="$1"
    local env_dir="$TERRAFORM_DIR/environments/$env"
    
    print_status "Running Terraform plan for $env environment..."
    
    cd "$env_dir"
    
    # Run terraform plan
    terraform plan -out=tfplan
    
    print_success "Terraform plan completed"
}

# Function to run Terraform apply
run_terraform_apply() {
    local env="$1"
    local env_dir="$TERRAFORM_DIR/environments/$env"
    local auto_approve="$2"
    
    print_status "Running Terraform apply for $env environment..."
    
    cd "$env_dir"
    
    # Run terraform apply
    if [ "$auto_approve" = true ]; then
        terraform apply -auto-approve
    else
        terraform apply tfplan
    fi
    
    print_success "Terraform apply completed"
}

# Function to run Terraform destroy
run_terraform_destroy() {
    local env="$1"
    local env_dir="$TERRAFORM_DIR/environments/$env"
    local auto_approve="$2"
    
    print_warning "Running Terraform destroy for $env environment..."
    print_warning "This will destroy all resources in the $env environment!"
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_status "Destroy cancelled"
        exit 0
    fi
    
    cd "$env_dir"
    
    # Run terraform destroy
    if [ "$auto_approve" = true ]; then
        terraform destroy -auto-approve
    else
        terraform destroy
    fi
    
    print_success "Terraform destroy completed"
}

# Function to get cluster info
get_cluster_info() {
    local env="$1"
    local env_dir="$TERRAFORM_DIR/environments/$env"
    
    print_status "Getting cluster information..."
    
    cd "$env_dir"
    
    # Get cluster name
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    
    if [ -n "$CLUSTER_NAME" ]; then
        print_success "Cluster name: $CLUSTER_NAME"
        
        # Get cluster endpoint
        CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "")
        if [ -n "$CLUSTER_ENDPOINT" ]; then
            print_success "Cluster endpoint: $CLUSTER_ENDPOINT"
        fi
        
        # Update kubeconfig
        if command -v aws &> /dev/null && command -v kubectl &> /dev/null; then
            print_status "Updating kubeconfig..."
            aws eks update-kubeconfig --region us-west-2 --name "$CLUSTER_NAME"
            print_success "Kubeconfig updated"
        fi
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -p|--plan-only)
            PLAN_ONLY=true
            shift
            ;;
        -y|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "Starting deployment for JavaScript 2D Game"
    print_status "Environment: $ENVIRONMENT"
    print_status "Action: $ACTION"
    
    # Validate inputs
    validate_environment "$ENVIRONMENT"
    validate_action "$ACTION"
    
    # Check prerequisites
    check_prerequisites
    
    # Initialize Terraform
    init_terraform "$ENVIRONMENT"
    
    # Execute Terraform action
    case "$ACTION" in
        plan)
            run_terraform_plan "$ENVIRONMENT"
            ;;
        apply)
            if [ "$PLAN_ONLY" = true ]; then
                run_terraform_plan "$ENVIRONMENT"
            else
                run_terraform_plan "$ENVIRONMENT"
                run_terraform_apply "$ENVIRONMENT" "$AUTO_APPROVE"
                get_cluster_info "$ENVIRONMENT"
            fi
            ;;
        destroy)
            run_terraform_destroy "$ENVIRONMENT" "$AUTO_APPROVE"
            ;;
    esac
    
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@"
