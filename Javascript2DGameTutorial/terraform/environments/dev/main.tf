# environments/dev/main.tf - Development Environment Main Configuration

# Local variables for this environment
locals {
  environment = "dev"
  
  # Cluster addons configuration - properly formatted
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }
  
  tags = merge(
    var.tags,
    {
      Environment = local.environment
    }
  )
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  name         = "${var.project_name}-${local.environment}"
  cidr         = var.vpc_cidr
  environment  = local.environment
  cluster_name = "${var.cluster_name}-${local.environment}"  # Add this for EKS subnet tagging
  
  # Optional: Configure NAT gateways based on environment
  single_nat_gateway = local.environment == "dev" ? true : false  # Use single NAT in dev to save costs
  
  tags = local.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"
  
  cluster_name        = "${var.cluster_name}-${local.environment}"
  kubernetes_version  = var.kubernetes_version  # Changed from cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets  # Changed from subnet_ids
  
  # Node group configuration
  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_instance_types = var.node_group_instance_types
  node_group_disk_size      = var.node_group_disk_size
  node_group_ami_type       = var.node_group_ami_type
  
  # Authentication
  authentication_mode = var.authentication_mode
  
  # Pass cluster addons
  cluster_addons = local.cluster_addons
  
  environment = local.environment
  tags        = local.tags
}

# IAM Role for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-${local.environment}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

# Addons Module - with proper configuration
module "addons" {
  source = "../../modules/addons"
  
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  vpc_id            = module.vpc.vpc_id
  aws_region        = var.aws_region
  
  # Addon toggles
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_metrics_server               = var.enable_metrics_server
  enable_karpenter                   = var.enable_karpenter
  enable_cert_manager                = var.enable_cert_manager
  enable_aws_cloudwatch_metrics      = var.enable_aws_cloudwatch_metrics
  
  # Chart versions
  aws_load_balancer_controller_chart_version = var.aws_load_balancer_controller_chart_version
  metrics_server_chart_version               = var.metrics_server_chart_version
  
  # Pass the native cluster addons
  cluster_addons = local.cluster_addons
  
  tags = local.tags
  
  depends_on = [module.eks]
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"
  
  repository_name = "${var.project_name}-${local.environment}"
  environment     = local.environment
  
  tags = local.tags
}

# Application Module
module "application" {
  source = "../../modules/application"
  
  project_name       = var.project_name
  cluster_name       = module.eks.cluster_name
  ecr_repository_url = module.ecr.repository_url
  
  # Application configuration
  game_replicas            = var.game_replicas
  container_cpu_limit      = var.container_cpu_limit
  container_memory_limit   = var.container_memory_limit
  container_cpu_request    = var.container_cpu_request
  container_memory_request = var.container_memory_request
  
  # Autoscaling
  enable_autoscaling = var.enable_autoscaling
  hpa_min_replicas   = var.hpa_min_replicas
  hpa_max_replicas   = var.hpa_max_replicas
  hpa_cpu_target     = var.hpa_cpu_target
  hpa_memory_target  = var.hpa_memory_target
  
  environment = local.environment
  tags        = local.tags
  
  depends_on = [module.eks, module.addons]
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = module.application.load_balancer_hostname
}

output "update_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}