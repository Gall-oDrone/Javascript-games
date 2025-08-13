# outputs.tf - Terraform outputs for modern EKS configuration

# Cluster Outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster's OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

# Node Group Outputs
output "node_groups" {
  description = "Details of the EKS managed node groups"
  value       = module.eks.eks_managed_node_groups
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.game.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.game.arn
}

# Load Balancer Outputs
output "load_balancer_hostname" {
  description = "The hostname of the Network Load Balancer"
  value       = try(kubernetes_service.game.status[0].load_balancer[0].ingress[0].hostname, "")
}

output "ingress_hostname" {
  description = "The hostname of the Application Load Balancer (ALB)"
  value       = try(kubernetes_ingress_v1.game.status[0].load_balancer[0].ingress[0].hostname, "")
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# AWS Region and AZ Info
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

# KMS Outputs
output "kms_key_id" {
  description = "ID of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.arn
}

# EKS Blueprints Addons Info
output "eks_blueprints_addons" {
  description = "Information about deployed EKS Blueprints addons"
  value = {
    aws_load_balancer_controller = var.enable_aws_load_balancer_controller
    metrics_server               = var.enable_metrics_server
    karpenter                   = var.enable_karpenter
    aws_cloudwatch_metrics      = var.enable_aws_cloudwatch_metrics
    cert_manager                = var.enable_cert_manager
  }
}

# Application Outputs
output "game_namespace" {
  description = "Kubernetes namespace for the game application"
  value       = kubernetes_namespace.game.metadata[0].name
}

output "game_deployment" {
  description = "Name of the game deployment"
  value       = kubernetes_deployment.game.metadata[0].name
}

output "game_service" {
  description = "Name of the game service"
  value       = kubernetes_service.game.metadata[0].name
}

# Connection Instructions
output "update_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "game_url" {
  description = "URL to access the game"
  value       = try(
    "http://${kubernetes_ingress_v1.game.status[0].load_balancer[0].ingress[0].hostname}",
    "http://${kubernetes_service.game.status[0].load_balancer[0].ingress[0].hostname}",
    "Service is still being provisioned..."
  )
}