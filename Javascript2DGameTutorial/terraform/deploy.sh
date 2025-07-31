#!/bin/bash

# JavaScript 2D Game - Terraform Deployment Script
# Based on AWS AppMod Blueprints patterns

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to configure AWS credentials
configure_aws() {
    print_status "Configuring AWS credentials..."
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    print_success "AWS configured for account: $AWS_ACCOUNT_ID in region: $AWS_REGION"
}

# Function to create S3 backend bucket
create_backend_bucket() {
    print_status "Creating S3 backend bucket for Terraform state..."
    
    BUCKET_NAME="javascript-2d-game-terraform-state-${AWS_ACCOUNT_ID}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_status "Backend bucket already exists: $BUCKET_NAME"
    else
        # Create bucket
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        print_success "Created backend bucket: $BUCKET_NAME"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    print_status "Building and pushing Docker image..."
    
    # Get ECR repository URL
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    
    if [ -z "$ECR_REPO_URL" ]; then
        print_warning "ECR repository not found. Please run 'terraform apply' first to create the repository."
        return 1
    fi
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO_URL"
    
    # Build image
    docker build -t "$ECR_REPO_URL:latest" ..
    
    # Push image
    docker push "$ECR_REPO_URL:latest"
    
    print_success "Docker image built and pushed successfully!"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    local ENVIRONMENT=$1
    
    print_status "Deploying infrastructure for environment: $ENVIRONMENT"
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var-file="environments/$ENVIRONMENT.tfvars" -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    print_success "Infrastructure deployed successfully!"
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application to EKS..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$(terraform output -raw cluster_name)"
    
    # Build and push Docker image
    build_and_push_image
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/
    
    print_success "Application deployed successfully!"
}

# Function to get deployment status
get_status() {
    print_status "Getting deployment status..."
    
    # Get cluster info
    echo "=== EKS Cluster Info ==="
    aws eks describe-cluster --region "$AWS_REGION" --name "$(terraform output -raw cluster_name)" --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' --output table
    
    # Get pod status
    echo -e "\n=== Pod Status ==="
    kubectl get pods -n javascript-2d-game
    
    # Get service info
    echo -e "\n=== Service Info ==="
    kubectl get svc -n javascript-2d-game
    
    # Get ingress info
    echo -e "\n=== Ingress Info ==="
    kubectl get ingress -n javascript-2d-game
    
    # Get load balancer URL
    echo -e "\n=== Load Balancer URL ==="
    kubectl get svc javascript-2d-game-service -n javascript-2d-game -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    echo ""
}

# Function to destroy infrastructure
destroy_infrastructure() {
    local ENVIRONMENT=$1
    
    print_warning "This will destroy all infrastructure for environment: $ENVIRONMENT"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying infrastructure..."
        terraform destroy -var-file="environments/$ENVIRONMENT.tfvars"
        print_success "Infrastructure destroyed successfully!"
    else
        print_status "Destroy cancelled."
    fi
}

# Main script
main() {
    local COMMAND=$1
    local ENVIRONMENT=$2
    
    # Default environment
    if [ -z "$ENVIRONMENT" ]; then
        ENVIRONMENT="dev"
    fi
    
    # Check if environment file exists
    if [ ! -f "environments/$ENVIRONMENT.tfvars" ]; then
        print_error "Environment file 'environments/$ENVIRONMENT.tfvars' not found!"
        exit 1
    fi
    
    case $COMMAND in
        "init")
            check_prerequisites
            configure_aws
            create_backend_bucket
            ;;
        "deploy")
            check_prerequisites
            configure_aws
            deploy_infrastructure "$ENVIRONMENT"
            deploy_application
            ;;
        "infrastructure")
            check_prerequisites
            configure_aws
            deploy_infrastructure "$ENVIRONMENT"
            ;;
        "application")
            deploy_application
            ;;
        "status")
            get_status
            ;;
        "destroy")
            destroy_infrastructure "$ENVIRONMENT"
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 {init|deploy|infrastructure|application|status|destroy} [environment]"
            echo ""
            echo "Commands:"
            echo "  init           - Initialize prerequisites and backend"
            echo "  deploy         - Deploy infrastructure and application"
            echo "  infrastructure - Deploy only infrastructure"
            echo "  application    - Deploy only application"
            echo "  status         - Show deployment status"
            echo "  destroy        - Destroy infrastructure"
            echo ""
            echo "Environments:"
            echo "  dev (default)  - Development environment"
            echo "  prod           - Production environment"
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 