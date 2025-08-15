#!/bin/bash

# Safe Cleanup script for JavaScript 2D Game EKS Infrastructure
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
    print_error "Usage: $0 <environment> [--force] [--cleanup-orphaned]"
    print_error "Example: $0 dev"
    print_error "Example: $0 dev --force (to skip confirmation)"
    print_error "Example: $0 dev --cleanup-orphaned (to clean up orphaned resources only)"
    exit 1
fi

ENVIRONMENT=$1
FORCE=false
CLEANUP_ORPHANED_ONLY=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --force)
            FORCE=true
            shift
            ;;
        --cleanup-orphaned)
            CLEANUP_ORPHANED_ONLY=true
            shift
            ;;
    esac
done

# Check if environment directory exists
ENVIRONMENT_DIR="environments/${ENVIRONMENT}"
if [ ! -d "$ENVIRONMENT_DIR" ]; then
    print_error "Environment directory $ENVIRONMENT_DIR not found!"
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

# Change to environment directory
cd "$ENVIRONMENT_DIR"

# Initialize Terraform
print_step "Initializing Terraform..."
terraform init

# Get cluster information from environment variables
print_step "Getting cluster information..."
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "javascript-2d-game-${ENVIRONMENT}")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

print_status "EKS Cluster Name: $CLUSTER_NAME"
print_status "AWS Region: $AWS_REGION"

# Check if cluster exists
if aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" &>/dev/null; then
    print_status "Cluster exists, proceeding with safe destruction..."
    
    # Try to configure kubectl to access the cluster
    if aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME" &>/dev/null; then
        print_status "Successfully configured kubectl"
        
        # Check if kubectl can reach the cluster
        if kubectl get nodes &>/dev/null; then
            print_status "Cluster is accessible, cleaning up Kubernetes resources..."
            
            # Delete Kubernetes resources manually to avoid Terraform errors
            print_step "Deleting Kubernetes resources..."
            
            # Delete Helm releases
            if kubectl get namespace kube-system &>/dev/null; then
                if helm list -n kube-system | grep -q "aws-load-balancer-controller"; then
                    print_status "Uninstalling AWS Load Balancer Controller..."
                    helm uninstall aws-load-balancer-controller -n kube-system || true
                fi
                
                if helm list -n kube-system | grep -q "metrics-server"; then
                    print_status "Uninstalling Metrics Server..."
                    helm uninstall metrics-server -n kube-system || true
                fi
            fi
            
            if kubectl get namespace karpenter &>/dev/null; then
                if helm list -n karpenter | grep -q "karpenter"; then
                    print_status "Uninstalling Karpenter..."
                    helm uninstall karpenter -n karpenter || true
                fi
            fi
            
            if kubectl get namespace cert-manager &>/dev/null; then
                if helm list -n cert-manager | grep -q "cert-manager"; then
                    print_status "Uninstalling Cert Manager..."
                    helm uninstall cert-manager -n cert-manager || true
                fi
            fi
            
            # Delete application resources
            if kubectl get namespace javascript-2d-game-${ENVIRONMENT} &>/dev/null; then
                print_status "Deleting application resources..."
                kubectl delete namespace javascript-2d-game-${ENVIRONMENT} || true
            fi
            
            # Delete service accounts
            if kubectl get serviceaccount aws-load-balancer-controller -n kube-system &>/dev/null; then
                print_status "Deleting AWS Load Balancer Controller service account..."
                kubectl delete serviceaccount aws-load-balancer-controller -n kube-system || true
            fi
            
            print_status "Kubernetes resources cleaned up"
        else
            print_warning "Cannot reach cluster, proceeding with Terraform destruction..."
        fi
    else
        print_warning "Cannot configure kubectl, proceeding with Terraform destruction..."
    fi
else
    print_warning "Cluster does not exist, proceeding with Terraform destruction..."
fi

# If only cleaning up orphaned resources, remove them from state and exit
if [ "$CLEANUP_ORPHANED_ONLY" = true ]; then
    print_step "Cleaning up orphaned resources from Terraform state..."
    
    # List of resources to remove from state if cluster is gone
    ORPHANED_RESOURCES=(
        "module.addons.kubernetes_service_account.aws_load_balancer_controller[0]"
        "module.addons.helm_release.aws_load_balancer_controller[0]"
        "module.addons.helm_release.metrics_server[0]"
        "module.addons.helm_release.karpenter[0]"
        "module.addons.helm_release.cert_manager[0]"
        "module.application.kubernetes_namespace.this"
        "module.application.kubernetes_deployment.this"
        "module.application.kubernetes_service.this"
        "module.application.kubernetes_horizontal_pod_autoscaler.this"
        "module.application.kubernetes_ingress_v1.this"
    )
    
    for resource in "${ORPHANED_RESOURCES[@]}"; do
        if terraform state list | grep -q "$resource"; then
            print_status "Removing $resource from state..."
            terraform state rm "$resource" || true
        else
            print_status "$resource not found in state, skipping..."
        fi
    done
    
    print_status "Orphaned resources removed from Terraform state"
    print_status "Cleanup completed successfully!"
    exit 0
fi

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

# Plan the destruction
print_step "Planning destruction..."
terraform plan -destroy -out=destroy-plan

# Apply the destruction
print_step "Destroying infrastructure..."
terraform apply destroy-plan

# Clean up plan file
rm -f destroy-plan

print_status "Infrastructure cleanup completed successfully!"

# Final cleanup check
print_step "Performing final cleanup checks..."

# Check if any orphaned resources remain
print_status "Checking for orphaned resources..."

# Check for orphaned load balancers
LB_COUNT=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?contains(LoadBalancerName, '$CLUSTER_NAME')].LoadBalancerArn" --output text | wc -w)
if [ "$LB_COUNT" -gt 0 ]; then
    print_warning "Found $LB_COUNT orphaned load balancer(s). You may need to delete them manually."
    aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?contains(LoadBalancerName, '$CLUSTER_NAME')].{Name:LoadBalancerName,ARN:LoadBalancerArn}" --output table
fi

# Check for orphaned security groups
SG_COUNT=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters "Name=group-name,Values=*$CLUSTER_NAME*" --query "SecurityGroups[].GroupId" --output text | wc -w)
if [ "$SG_COUNT" -gt 0 ]; then
    print_warning "Found $SG_COUNT orphaned security group(s). You may need to delete them manually."
fi

# Check for orphaned IAM roles
ROLE_COUNT=$(aws iam list-roles --query "Roles[?contains(RoleName, '$CLUSTER_NAME')].RoleName" --output text | wc -w)
if [ "$ROLE_COUNT" -gt 0 ]; then
    print_warning "Found $ROLE_COUNT orphaned IAM role(s). You may need to delete them manually."
    aws iam list-roles --query "Roles[?contains(RoleName, '$CLUSTER_NAME')].RoleName" --output table
fi

print_status "Cleanup summary:"
echo "  - EKS Cluster: $CLUSTER_NAME (DESTROYED)"
echo "  - VPC and networking resources (DESTROYED)"
echo "  - ECR Repository (DESTROYED)"
echo "  - IAM roles and policies (DESTROYED)"
echo "  - Load balancers (DESTROYED)"

print_status "All resources have been cleaned up!"
print_status "If any orphaned resources were found, you may need to delete them manually." 