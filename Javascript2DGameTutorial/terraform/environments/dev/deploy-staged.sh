#!/bin/bash
set -e

echo "🚀 Starting staged deployment for dev environment..."

# Stage 1: Deploy infrastructure only (VPC, EKS, ECR)
echo "📦 Stage 1: Deploying core infrastructure (VPC, EKS, ECR)..."
terraform init
terraform apply -target=module.vpc -target=module.eks -target=module.ecr -auto-approve

# Wait for cluster to be ready
echo "⏳ Waiting for EKS cluster to be ready (60 seconds)..."
sleep 60

# Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region us-west-2 --name javascript-2d-game-dev

# Verify cluster is accessible
echo "✅ Verifying cluster access..."
kubectl get nodes || echo "Warning: Could not access cluster yet"

# Stage 2: Deploy everything (including addons and application)
echo "📦 Stage 2: Deploying addons and application..."
terraform apply -auto-approve

echo "✅ Deployment complete!"

# Get load balancer URL
echo "🌐 Getting application URL..."
kubectl get svc -n javascript-2d-game-dev