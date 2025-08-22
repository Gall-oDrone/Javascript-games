#!/bin/bash
# Debug and fix ALB issues for JavaScript 2D Game

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

# Check current state
print_info "Checking current Kubernetes resources..."

NAMESPACE="javascript-2d-game-dev"
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    NAMESPACE="javascript-2d-game"
fi

print_info "Using namespace: $NAMESPACE"

# Check pods
print_info "Checking pods..."
kubectl get pods -n $NAMESPACE

# Check service
print_info "Checking service..."
kubectl get svc -n $NAMESPACE

# Check ingress
print_info "Checking ingress..."
kubectl get ingress -n $NAMESPACE

# Get detailed ingress info
print_info "Ingress details:"
kubectl describe ingress -n $NAMESPACE

# Check AWS Load Balancer Controller
print_info "Checking AWS Load Balancer Controller..."
kubectl get pods -n kube-system | grep aws-load-balancer-controller || print_warning "AWS Load Balancer Controller not found!"

# Check controller logs
print_info "Recent AWS Load Balancer Controller logs:"
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=20 || true

# Quick fix - Delete and recreate ingress
print_warning "Attempting to fix the ingress configuration..."

# First, let's check if the service has endpoints
print_info "Checking service endpoints..."
kubectl get endpoints -n $NAMESPACE

# Delete the existing ingress
print_info "Deleting existing ingress..."
kubectl delete ingress --all -n $NAMESPACE || true

# Wait a moment
sleep 5

# Create a simple working ingress
print_info "Creating new ingress configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: javascript-2d-game-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/success-codes: "200-399"
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: javascript-2d-game-dev-service
      port:
        number: 80
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: javascript-2d-game-dev-service
            port:
              number: 80
EOF

print_success "New ingress created!"

# Wait for ALB to be provisioned
print_info "Waiting for ALB to be provisioned (this may take 2-3 minutes)..."
sleep 30

# Check new ingress status
print_info "Checking new ingress status..."
kubectl get ingress -n $NAMESPACE

# Get the ALB hostname
ALB_HOSTNAME=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$ALB_HOSTNAME" ]; then
    print_success "ALB hostname: $ALB_HOSTNAME"
    print_info "Application should be accessible at: http://$ALB_HOSTNAME"
    
    # Test the endpoint
    print_info "Testing the endpoint..."
    curl -I "http://$ALB_HOSTNAME" 2>/dev/null | head -n 5 || print_warning "Could not reach the endpoint yet"
else
    print_warning "ALB hostname not ready yet. Check again in a minute with:"
    echo "kubectl get ingress -n $NAMESPACE"
fi

# Additional debugging info
print_info "Target group health check status can be viewed in AWS Console:"
echo "https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#TargetGroups"

print_info "If targets are unhealthy, check:"
echo "1. Pod logs: kubectl logs -f deployment/javascript-2d-game -n $NAMESPACE"
echo "2. Service endpoints: kubectl get endpoints -n $NAMESPACE"
echo "3. Security groups in AWS Console"

# Check if there are any events
print_info "Recent events in namespace:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

print_success "Debugging complete!"