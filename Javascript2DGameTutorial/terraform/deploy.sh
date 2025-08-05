#!/bin/bash

# Deployment script for JavaScript 2D Game EKS Infrastructure
# Based on AWS Load Balancer Controller best practices
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
    print_error "Usage: $0 <environment>"
    print_error "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "Environment file $TFVARS_FILE not found!"
    exit 1
fi

print_status "Starting deployment for environment: $ENVIRONMENT"

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

print_status "Terraform version: $(terraform version | head -n1)"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You'll need it to interact with the cluster after deployment."
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_warning "Helm is not installed. The AWS Load Balancer Controller will be installed via Terraform."
fi

# Initialize Terraform
print_step "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_step "Validating Terraform configuration..."
terraform validate

# Plan the deployment
print_step "Planning deployment..."
terraform plan -var-file="$TFVARS_FILE" -out=tfplan

# Ask for confirmation
echo
print_warning "Review the plan above. Do you want to proceed with the deployment? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled by user"
    exit 0
fi

# Apply the deployment
print_step "Applying deployment..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

print_status "Infrastructure deployment completed successfully!"

# Get cluster information
print_step "Getting cluster information..."
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "javascript-2d-game-${ENVIRONMENT}")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

print_status "EKS Cluster Name: $CLUSTER_NAME"
print_status "AWS Region: $AWS_REGION"

# Configure kubectl
print_step "Configuring kubectl..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

# Wait for cluster to be ready
print_step "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready nodes --all --timeout=300s

# Check if AWS Load Balancer Controller is running
print_step "Checking AWS Load Balancer Controller status..."
if kubectl get pods -n kube-system | grep -q aws-load-balancer-controller; then
    print_status "AWS Load Balancer Controller is installed"
    
    # Wait for AWS Load Balancer Controller to be ready
    print_step "Waiting for AWS Load Balancer Controller to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s
    
    print_status "AWS Load Balancer Controller is ready!"
else
    print_warning "AWS Load Balancer Controller not found. It may still be installing..."
fi

# Check cluster status
print_step "Checking cluster status..."
echo "=== EKS Cluster Info ==="
aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' --output table

echo -e "\n=== Node Status ==="
kubectl get nodes

echo -e "\n=== Pod Status ==="
kubectl get pods -n javascript-2d-game

echo -e "\n=== Service Status ==="
kubectl get svc -n javascript-2d-game

echo -e "\n=== Ingress Status ==="
kubectl get ingress -n javascript-2d-game

# Get load balancer URL if available
print_step "Getting load balancer information..."
LB_HOSTNAME=$(kubectl get svc javascript-2d-game-service -n javascript-2d-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available yet")

if [ "$LB_HOSTNAME" != "Not available yet" ]; then
    print_status "Load Balancer URL: http://$LB_HOSTNAME"
else
    print_warning "Load balancer is still being provisioned. This may take a few minutes."
fi

print_status "Deployment completed successfully!"

print_status "Useful commands:"
echo "  Check cluster status: kubectl get nodes"
echo "  View game pods: kubectl get pods -n javascript-2d-game"
echo "  View game logs: kubectl logs -f deployment/javascript-2d-game -n javascript-2d-game"
echo "  Access game: kubectl port-forward svc/javascript-2d-game-service 8080:80 -n javascript-2d-game"
echo "  Check AWS Load Balancer Controller: kubectl get pods -n kube-system | grep aws-load-balancer-controller" 