#!/bin/bash

# Manual cleanup script for all Helm addons and Kubernetes resources
# This script removes all Helm releases and their resources without using Terraform

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

# Function to check if a namespace exists
namespace_exists() {
    kubectl get namespace "$1" &> /dev/null
}

# Function to uninstall a Helm release
uninstall_helm_release() {
    local release_name=$1
    local namespace=$2
    
    if helm list -n "$namespace" | grep -q "$release_name"; then
        print_info "Uninstalling Helm release: $release_name from namespace: $namespace"
        helm uninstall "$release_name" -n "$namespace" --wait --timeout 5m || {
            print_warning "Normal uninstall failed, forcing deletion..."
            helm uninstall "$release_name" -n "$namespace" --no-hooks || true
        }
        print_success "Uninstalled $release_name"
    else
        print_info "Release $release_name not found in namespace $namespace"
    fi
}

# Function to clean up stuck resources
cleanup_stuck_resources() {
    local namespace=$1
    
    print_info "Cleaning up stuck resources in namespace: $namespace"
    
    # Delete all pods forcefully
    kubectl delete pods --all -n "$namespace" --grace-period=0 --force 2>/dev/null || true
    
    # Delete all PVCs
    kubectl delete pvc --all -n "$namespace" --grace-period=0 --force 2>/dev/null || true
    
    # Delete all services
    kubectl delete svc --all -n "$namespace" 2>/dev/null || true
    
    # Delete all deployments
    kubectl delete deployment --all -n "$namespace" 2>/dev/null || true
    
    # Delete all statefulsets
    kubectl delete statefulset --all -n "$namespace" 2>/dev/null || true
    
    # Delete all daemonsets
    kubectl delete daemonset --all -n "$namespace" 2>/dev/null || true
    
    # Delete all configmaps
    kubectl delete configmap --all -n "$namespace" 2>/dev/null || true
    
    # Delete all secrets
    kubectl delete secret --all -n "$namespace" 2>/dev/null || true
}

print_warning "This script will remove ALL Helm addons and their resources from your cluster"
print_warning "This includes: AWS Load Balancer Controller, Metrics Server, Prometheus Stack, Karpenter, Cert Manager, etc."
echo ""
read -p "Are you sure you want to continue? Type 'yes' to proceed: " -r response
if [[ ! "$response" == "yes" ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

print_info "Starting cleanup of all Helm addons..."

# 1. List all Helm releases across all namespaces
print_info "Discovering all Helm releases..."
helm list --all-namespaces

# 2. Uninstall Prometheus Stack
if namespace_exists "monitoring"; then
    print_info "Cleaning up Prometheus Stack..."
    uninstall_helm_release "kube-prometheus-stack" "monitoring"
    cleanup_stuck_resources "monitoring"
    
    # Delete the monitoring namespace
    print_info "Deleting monitoring namespace..."
    kubectl delete namespace monitoring --grace-period=0 --force 2>/dev/null || true
fi

# 3. Uninstall AWS Load Balancer Controller
print_info "Cleaning up AWS Load Balancer Controller..."
uninstall_helm_release "aws-load-balancer-controller" "kube-system"

# Delete AWS LB Controller resources
kubectl delete deployment aws-load-balancer-controller -n kube-system 2>/dev/null || true
kubectl delete service aws-load-balancer-webhook-service -n kube-system 2>/dev/null || true
kubectl delete serviceaccount aws-load-balancer-controller -n kube-system 2>/dev/null || true
kubectl delete clusterrole aws-load-balancer-controller 2>/dev/null || true
kubectl delete clusterrolebinding aws-load-balancer-controller 2>/dev/null || true
kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook 2>/dev/null || true
kubectl delete mutatingwebhookconfiguration aws-load-balancer-webhook 2>/dev/null || true

# 4. Uninstall Metrics Server
print_info "Cleaning up Metrics Server..."
uninstall_helm_release "metrics-server" "kube-system"

# 5. Uninstall Karpenter
if namespace_exists "karpenter"; then
    print_info "Cleaning up Karpenter..."
    uninstall_helm_release "karpenter" "karpenter"
    cleanup_stuck_resources "karpenter"
    
    # Delete Karpenter CRDs
    kubectl delete crd provisioners.karpenter.sh 2>/dev/null || true
    kubectl delete crd awsnodeinstanceclasses.karpenter.k8s.aws 2>/dev/null || true
    kubectl delete crd machines.karpenter.sh 2>/dev/null || true
    
    # Delete the karpenter namespace
    kubectl delete namespace karpenter --grace-period=0 --force 2>/dev/null || true
fi

# 6. Uninstall Cert Manager
if namespace_exists "cert-manager"; then
    print_info "Cleaning up Cert Manager..."
    uninstall_helm_release "cert-manager" "cert-manager"
    cleanup_stuck_resources "cert-manager"
    
    # Delete Cert Manager CRDs
    kubectl delete crd certificaterequests.cert-manager.io 2>/dev/null || true
    kubectl delete crd certificates.cert-manager.io 2>/dev/null || true
    kubectl delete crd challenges.acme.cert-manager.io 2>/dev/null || true
    kubectl delete crd clusterissuers.cert-manager.io 2>/dev/null || true
    kubectl delete crd issuers.cert-manager.io 2>/dev/null || true
    kubectl delete crd orders.acme.cert-manager.io 2>/dev/null || true
    
    # Delete the cert-manager namespace
    kubectl delete namespace cert-manager --grace-period=0 --force 2>/dev/null || true
fi

# 7. Clean up any other Helm releases in kube-system
print_info "Checking for other Helm releases in kube-system..."
for release in $(helm list -n kube-system -q); do
    uninstall_helm_release "$release" "kube-system"
done

# 8. Clean up any other Helm releases in default namespace
print_info "Checking for other Helm releases in default namespace..."
for release in $(helm list -n default -q); do
    uninstall_helm_release "$release" "default"
done

# 9. Clean up application namespace if it exists
if namespace_exists "javascript-2d-game"; then
    print_info "Cleaning up javascript-2d-game namespace..."
    cleanup_stuck_resources "javascript-2d-game"
    kubectl delete namespace javascript-2d-game --grace-period=0 --force 2>/dev/null || true
fi

if namespace_exists "javascript-2d-game-dev"; then
    print_info "Cleaning up javascript-2d-game-dev namespace..."
    cleanup_stuck_resources "javascript-2d-game-dev"
    kubectl delete namespace javascript-2d-game-dev --grace-period=0 --force 2>/dev/null || true
fi

# 10. Clean up any Custom Resource Definitions (CRDs) that might be left
print_info "Cleaning up remaining CRDs..."
kubectl get crd | grep -E 'aws|monitoring|prometheus|grafana|alertmanager' | awk '{print $1}' | xargs -r kubectl delete crd 2>/dev/null || true

# 11. Clean up any remaining PVs
print_info "Cleaning up Persistent Volumes..."
kubectl get pv | grep -E 'Released|Failed' | awk '{print $1}' | xargs -r kubectl delete pv 2>/dev/null || true

# 12. List remaining Helm releases to verify cleanup
print_info "Remaining Helm releases (should be empty or minimal):"
helm list --all-namespaces

# 13. Clean up AWS resources (Load Balancers, Target Groups)
print_info "Checking for orphaned AWS Load Balancers..."
CLUSTER_NAME="javascript-2d-game-cluster"  # Update this if your cluster name is different
REGION="us-west-2"

# List load balancers that might be orphaned
aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[?contains(LoadBalancerName, 'k8s')].{Name:LoadBalancerName,ARN:LoadBalancerArn,State:State.Code}" --output table 2>/dev/null || true

print_warning "If you see any load balancers above, you may need to delete them manually from AWS Console"
print_warning "Check: https://console.aws.amazon.com/ec2/v2/home?region=$REGION#LoadBalancers"

# 14. Final verification
print_info "Final verification..."
echo ""
print_info "Namespaces:"
kubectl get namespaces
echo ""
print_info "Helm releases:"
helm list --all-namespaces
echo ""
print_info "Persistent Volumes:"
kubectl get pv
echo ""
print_info "Persistent Volume Claims (all namespaces):"
kubectl get pvc --all-namespaces

print_success "Cleanup complete!"
print_info "Note: Some AWS resources like Load Balancers might take a few minutes to be fully deleted"
print_info "Check your AWS Console to ensure all resources are cleaned up"

# Optional: Show what's left in kube-system that might be from addons
echo ""
print_info "Remaining deployments in kube-system (should only show core components):"
kubectl get deployments -n kube-system

echo ""
print_info "If you want to reinstall addons, you can now do so with Terraform or Helm"