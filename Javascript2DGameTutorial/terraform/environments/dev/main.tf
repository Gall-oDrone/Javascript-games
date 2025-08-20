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
    # ADD EBS CSI DRIVER HERE
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.eks.ebs_csi_driver_iam_role_arn
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
  cluster_name = var.cluster_name
  
  # Optional: Configure NAT gateways based on environment
  single_nat_gateway = local.environment == "dev" ? true : false
  
  tags = local.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"
  
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets
  
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

# Null resource to ensure cluster is ready
resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]
  
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# Time delay to ensure EKS cluster is fully operational
resource "time_sleep" "wait_for_eks" {
  depends_on = [
    module.eks,
    null_resource.wait_for_cluster
  ]
  
  create_duration = "60s"
}

# Create a GP3 StorageClass (more cost-effective than GP2)
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"  # Make this the default
    }
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type      = "gp3"
    fsType    = "ext4"
    encrypted = "true"
  }
  
  # Make sure this runs AFTER the EBS CSI driver is installed
  depends_on = [
    module.eks,
    time_sleep.wait_for_eks
  ]
}

# Addons Module - with proper configuration and dependencies
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
  
  # Prometheus configuration - USE GP3 for all storage
  enable_prometheus_stack = var.enable_prometheus_stack
  prometheus_stack_chart_version = "51.3.0"
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size = var.grafana_storage_size
  
  tags = local.tags
  
  depends_on = [
    module.eks,
    time_sleep.wait_for_eks,
    null_resource.wait_for_cluster,
    kubernetes_storage_class.gp3  # Wait for GP3 StorageClass to be created
  ]
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
  app_name                    = "${var.project_name}-${local.environment}"
  namespace                   = "${var.project_name}-${local.environment}"
  replicas                   = var.game_replicas
  game_replicas              = var.game_replicas
  container_cpu_limit        = var.container_cpu_limit
  container_memory_limit     = var.container_memory_limit
  container_cpu_request      = var.container_cpu_request
  container_memory_request   = var.container_memory_request
  
  # Autoscaling
  enable_autoscaling = var.enable_autoscaling
  hpa_min_replicas   = var.hpa_min_replicas
  hpa_max_replicas   = var.hpa_max_replicas
  hpa_cpu_target     = var.hpa_cpu_target
  hpa_memory_target  = var.hpa_memory_target
  
  environment = local.environment
  tags        = local.tags
  
  depends_on = [
    module.eks, 
    module.addons,
    time_sleep.wait_for_eks
  ]
}