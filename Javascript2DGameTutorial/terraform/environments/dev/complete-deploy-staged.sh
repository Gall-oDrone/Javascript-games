#!/bin/bash
# Complete deployment script for dev environment with Docker build and push
set -e

echo "🚀 Starting complete deployment for dev environment..."

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

# Function to wait for any Kubernetes resource to be ready
wait_for_resource() {
    local resource_type=$1  # e.g., "ingress", "service"
    local resource_name=$2  # e.g., "javascript-2d-game-ingress"
    local namespace=$3
    local field_path=$4     # e.g., ".status.loadBalancer.ingress[0].hostname"
    local max_wait=${5:-300}  # Default 5 minutes
    
    local elapsed=0
    local interval=5
    
    print_info "Waiting for $resource_type/$resource_name to be ready..."
    
    while [ $elapsed -lt $max_wait ]; do
        result=$(kubectl get $resource_type $resource_name -n $namespace -o jsonpath="$field_path" 2>/dev/null || echo "")
        
        if [ -n "$result" ]; then
            print_success "$resource_type/$resource_name is ready: $result"
            echo "$result"  # Return the result
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
        
        if [ $((elapsed % 30)) -eq 0 ]; then
            print_info "Still waiting... ($elapsed seconds elapsed)"
        fi
    done
    
    print_warning "Timeout waiting for $resource_type/$resource_name"
    return 1
}

# Function to wait specifically for ALB to be ready
wait_for_alb() {
    local namespace=$1
    local max_attempts=60  # 5 minutes (60 * 5 seconds)
    local attempt=0
    
    print_info "⏳ Waiting for ALB to be provisioned (this may take 2-3 minutes)..."
    
    while [ $attempt -lt $max_attempts ]; do
        # Try to get the ALB hostname from the ingress
        LB_HOSTNAME=$(kubectl get ingress -n $namespace -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [ -n "$LB_HOSTNAME" ]; then
            print_success "✅ ALB is ready! Hostname: $LB_HOSTNAME"
            
            # Wait a bit more for the ALB to be fully operational
            print_info "Waiting 30 seconds for ALB to become fully operational..."
            sleep 30
            
            # Test if the ALB is responding
            print_info "Testing ALB connectivity..."
            if curl -s -o /dev/null -w "%{http_code}" "http://$LB_HOSTNAME" | grep -q "200\|301\|302\|404"; then
                print_success "✅ ALB is responding!"
                echo "$LB_HOSTNAME"  # Return the hostname
                return 0
            else
                print_warning "ALB created but not yet responding, waiting..."
            fi
        fi
        
        # Show progress
        if [ $((attempt % 6)) -eq 0 ]; then  # Every 30 seconds
            print_info "Still waiting for ALB... ($(($attempt * 5)) seconds elapsed)"
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_warning "⚠️ Timeout waiting for ALB after 5 minutes"
    return 1
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
}

# Function to check if the Dockerfile exists
check_dockerfile() {
    # Look for Dockerfile in various possible locations
    DOCKERFILE_LOCATIONS=(
        "./Dockerfile"
        "../Dockerfile"
        "../../Dockerfile"
        "../../../Dockerfile"
        "../../../../game/Dockerfile"
        "../../../game/Dockerfile"
        "../../game/Dockerfile"
    )
    
    DOCKERFILE_PATH=""
    for location in "${DOCKERFILE_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            DOCKERFILE_PATH="$location"
            DOCKERFILE_DIR=$(dirname "$location")
            print_success "Found Dockerfile at: $DOCKERFILE_PATH"
            break
        fi
    done
    
    if [ -z "$DOCKERFILE_PATH" ]; then
        print_error "Dockerfile not found! Please ensure Dockerfile exists in the project."
        print_info "Searched locations:"
        for location in "${DOCKERFILE_LOCATIONS[@]}"; do
            echo "  - $location"
        done
        exit 1
    fi
}

# Check prerequisites
print_info "Checking prerequisites..."
check_docker
check_dockerfile

# Stage 1: Deploy infrastructure only (VPC, EKS, ECR)
print_info "📦 Stage 1: Deploying core infrastructure (VPC, EKS, ECR)..."
terraform init -upgrade
terraform apply -target=module.vpc -target=module.eks -target=module.ecr -auto-approve

# Wait for cluster to be ready
print_info "⏳ Waiting for EKS cluster to be ready (90 seconds)..."
sleep 90

# Get outputs from Terraform
print_info "📋 Getting infrastructure details..."
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

if [ -z "$ECR_REPO_URL" ]; then
    print_error "Failed to get ECR repository URL from Terraform outputs"
    exit 1
fi

if [ -z "$CLUSTER_NAME" ]; then
    print_error "Failed to get cluster name from Terraform outputs"
    exit 1
fi

print_success "ECR Repository URL: $ECR_REPO_URL"
print_success "Cluster Name: $CLUSTER_NAME"
print_success "AWS Region: $AWS_REGION"

# Update kubeconfig
print_info "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster is accessible
print_info "✅ Verifying cluster access..."
if kubectl get nodes; then
    print_success "Cluster is accessible"
else
    print_warning "Could not access cluster yet, continuing anyway..."
fi

# Stage 2: Build and Push Docker Image
print_info "📦 Stage 2: Building and pushing Docker image to ECR..."

# Authenticate with ECR
print_info "🔐 Authenticating with ECR..."
ECR_REGISTRY=$(echo $ECR_REPO_URL | cut -d'/' -f1)
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build the Docker image
print_info "🔨 Building Docker image..."
cd "$DOCKERFILE_DIR"

# Check if we need sudo for Docker commands
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    print_warning "Docker requires sudo, using sudo for Docker commands..."
    DOCKER_CMD="sudo docker"
fi

$DOCKER_CMD build -t javascript-2d-game .

# Tag the image for ECR
print_info "🏷️  Tagging image for ECR..."
$DOCKER_CMD tag javascript-2d-game:latest $ECR_REPO_URL:latest

# Push to ECR
print_info "⬆️  Pushing image to ECR..."
$DOCKER_CMD push $ECR_REPO_URL:latest

print_success "Docker image pushed successfully!"

# Return to terraform directory
cd - > /dev/null

# Stage 3: Deploy everything (including addons and application)
print_info "📦 Stage 3: Deploying addons and application..."
terraform apply -auto-approve

# Wait for deployments to stabilize
print_info "⏳ Waiting for deployments to stabilize (30 seconds)..."
sleep 30

# Stage 4: Verify and Update Kubernetes Deployment
print_info "📦 Stage 4: Verifying and updating Kubernetes deployment..."

# Check if namespace exists
NAMESPACE="javascript-2d-game-dev"
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    print_warning "Namespace $NAMESPACE not found, trying without suffix..."
    NAMESPACE="javascript-2d-game"
fi

# Check if deployment exists
if kubectl get deployment -n $NAMESPACE &>/dev/null; then
    print_info "🔄 Restarting deployment to pull latest image..."
    kubectl rollout restart deployment -n $NAMESPACE
    
    print_info "⏳ Waiting for rollout to complete..."
    kubectl rollout status deployment -n $NAMESPACE --timeout=5m || true
    
    print_success "Deployment updated with latest image!"
else
    print_warning "No deployment found in namespace $NAMESPACE"
fi

# Stage 5: Final Verification
print_info "📦 Stage 5: Final verification..."

# Check pods
print_info "Checking pods..."
kubectl get pods -n $NAMESPACE

# Wait for ALB using the dedicated function
LB_HOSTNAME=$(wait_for_alb "$NAMESPACE")
if [ $? -eq 0 ] && [ -n "$LB_HOSTNAME" ]; then
    print_success "✅ Application is fully deployed and accessible!"
    print_success "🌐 Application URL: http://$LB_HOSTNAME"
    
    # Perform a final health check
    print_info "Performing final health check..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_HOSTNAME" 2>/dev/null || echo "000")
    
    case $HTTP_STATUS in
        200|301|302)
            print_success "✅ Application is healthy (HTTP $HTTP_STATUS)"
            ;;
        404)
            print_warning "⚠️ ALB is responding but application might not be serving content (HTTP 404)"
            ;;
        000)
            print_warning "⚠️ Could not connect to ALB (DNS might still be propagating)"
            ;;
        *)
            print_warning "⚠️ Unexpected HTTP status: $HTTP_STATUS"
            ;;
    esac
else
    print_warning "ALB provisioning timed out or failed"
    
    # Alternative: Try using the generic wait function for the ingress
    print_info "Attempting alternative wait method..."
    INGRESS_NAME="${var.project_name}-${local.environment}-ingress"
    LB_HOSTNAME=$(wait_for_resource "ingress" "$INGRESS_NAME" "$NAMESPACE" ".status.loadBalancer.ingress[0].hostname" 60)
    
    if [ -n "$LB_HOSTNAME" ]; then
        print_success "✅ Found ALB hostname: http://$LB_HOSTNAME"
    else
        print_warning "Could not get ALB hostname. Check manually with:"
        echo "  kubectl get ingress -n $NAMESPACE"
    fi
fi

print_success "✅ Deployment complete!"

# Provide helpful commands
echo ""
print_info "📝 Useful commands:"
echo "  - Check pods: kubectl get pods -n $NAMESPACE"
echo "  - View logs: kubectl logs -f deployment/javascript-2d-game -n $NAMESPACE"
echo "  - Port forward: kubectl port-forward svc/javascript-2d-game-service 8080:80 -n $NAMESPACE"
echo "  - Get service: kubectl get svc -n $NAMESPACE"

# Optional: Port forwarding for immediate testing
echo ""
read -p "Do you want to set up port forwarding for local testing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setting up port forwarding..."
    print_info "Access the game at: http://localhost:8080"
    print_info "Press Ctrl+C to stop port forwarding"
    kubectl port-forward svc/javascript-2d-game-dev-service 8080:80 -n $NAMESPACE
fi