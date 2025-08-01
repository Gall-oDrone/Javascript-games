#!/bin/bash

# Phase 1: Test Current Setup
# This script validates the fixes and tests the deployment

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Phase 1: Test Current Setup${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to validate AWS configuration
validate_aws() {
    print_info "Validating AWS configuration..."
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure'"
        exit 1
    fi
    
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    print_success "AWS configured for account: $AWS_ACCOUNT in region: $AWS_REGION"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_info "Validating Terraform configuration..."
    
    if ! terraform validate; then
        print_error "Terraform configuration validation failed"
        exit 1
    fi
    
    print_success "Terraform configuration is valid"
}

# Function to check availability zones
check_availability_zones() {
    print_info "Checking availability zones..."
    
    AWS_REGION=$(aws configure get region)
    AZ_COUNT=$(aws ec2 describe-availability-zones --region $AWS_REGION --query 'AvailabilityZones[?State==`available`]' --output table | grep -c "available" || echo "0")
    
    if [ "$AZ_COUNT" -lt 2 ]; then
        print_error "Region $AWS_REGION has only $AZ_COUNT available AZs. At least 2 are required."
        exit 1
    fi
    
    print_success "Region $AWS_REGION has $AZ_COUNT available AZs"
    
    # Show AZs
    print_info "Available AZs:"
    aws ec2 describe-availability-zones --region $AWS_REGION --query 'AvailabilityZones[?State==`available`].ZoneName' --output table
}

# Function to create Terraform plan
create_plan() {
    local ENVIRONMENT=$1
    
    print_info "Creating Terraform plan for $ENVIRONMENT environment..."
    
    if [ ! -f "environments/$ENVIRONMENT.tfvars" ]; then
        print_error "Environment file 'environments/$ENVIRONMENT.tfvars' not found!"
        exit 1
    fi
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        terraform init
    fi
    
    # Create plan
    terraform plan -var-file="environments/$ENVIRONMENT.tfvars" -out=tfplan
    
    print_success "Terraform plan created successfully"
}

# Function to deploy with progressive approach
deploy_progressive() {
    local ENVIRONMENT=$1
    
    print_info "Starting progressive deployment for $ENVIRONMENT environment..."
    
    # Step 1: Deploy VPC
    print_info "Step 1: Deploying VPC..."
    terraform apply -target=module.vpc -var-file="environments/$ENVIRONMENT.tfvars" -auto-approve
    
    # Step 2: Deploy EKS
    print_info "Step 2: Deploying EKS cluster..."
    terraform apply -target=module.eks -var-file="environments/$ENVIRONMENT.tfvars" -auto-approve
    
    # Step 3: Deploy everything else
    print_info "Step 3: Deploying remaining resources..."
    terraform apply -var-file="environments/$ENVIRONMENT.tfvars" -auto-approve
    
    print_success "Progressive deployment completed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # Get cluster name from Terraform output
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "javascript-2d-game-dev")
    
    # Update kubeconfig
    print_info "Updating kubeconfig for cluster: $CLUSTER_NAME"
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $(aws configure get region)
    
    # Check cluster status
    print_info "Checking EKS cluster status..."
    kubectl cluster-info
    
    # Check nodes
    print_info "Checking EKS nodes..."
    kubectl get nodes
    
    # Check pods
    print_info "Checking game pods..."
    kubectl get pods -n javascript-2d-game
    
    # Check services
    print_info "Checking services..."
    kubectl get svc -n javascript-2d-game
    
    # Get load balancer URL
    print_info "Getting load balancer URL..."
    LB_URL=$(kubectl get svc javascript-2d-game-service -n javascript-2d-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
    
    if [ "$LB_URL" != "Not ready yet" ]; then
        print_success "Load balancer URL: http://$LB_URL"
        print_info "You can access your game at: http://$LB_URL"
    else
        print_warning "Load balancer is still being provisioned. Check again in a few minutes."
    fi
}

# Function to show outputs
show_outputs() {
    print_info "Terraform outputs:"
    terraform output
}

# Function to run full test
run_full_test() {
    local ENVIRONMENT=$1
    
    print_header
    
    check_prerequisites
    validate_aws
    validate_terraform
    check_availability_zones
    create_plan "$ENVIRONMENT"
    
    echo ""
    print_info "Ready to deploy? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        deploy_progressive "$ENVIRONMENT"
        verify_deployment
        show_outputs
    else
        print_info "Deployment cancelled. You can run the plan manually with:"
        echo "terraform apply tfplan"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 {test|plan|deploy|verify} [environment]"
    echo ""
    echo "Commands:"
    echo "  test     - Run full validation and deployment test"
    echo "  plan     - Create Terraform plan only"
    echo "  deploy   - Deploy with progressive approach"
    echo "  verify   - Verify deployment status"
    echo ""
    echo "Environment: dev (default) or prod"
    echo ""
    echo "Examples:"
    echo "  $0 test dev"
    echo "  $0 plan prod"
    echo "  $0 deploy dev"
    echo "  $0 verify"
}

# Main function
main() {
    local COMMAND=$1
    local ENVIRONMENT=$2
    
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi
    
    case $COMMAND in
        "test")
            run_full_test "$ENVIRONMENT"
            ;;
        "plan")
            check_prerequisites
            validate_aws
            validate_terraform
            check_availability_zones
            create_plan "$ENVIRONMENT"
            ;;
        "deploy")
            check_prerequisites
            validate_aws
            deploy_progressive "$ENVIRONMENT"
            ;;
        "verify")
            verify_deployment
            show_outputs
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 