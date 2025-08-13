# Main Terraform configuration for JavaScript 2D Game
# Following AWS Blueprints best practices with modular structure

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "terraform"
    }
  }
}

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Get EKS cluster auth token
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  authentication_mode = var.authentication_mode
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets
  node_groups         = var.node_groups

  tags = local.common_tags
}

# Addons Module
module "addons" {
  source = "./modules/addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.eks.ebs_csi_driver_iam_role_arn
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_config = {
    chart_version = "1.6.2"
    set = [
      {
        name  = "enableWebhook"
        value = "true"
      },
      {
        name  = "enableWebhookSecret"
        value = "true"
      },
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "region"
        value = var.aws_region
      }
    ]
  }

  enable_metrics_server = true

  tags = local.common_tags
}

# Wait for the cluster to be ready before creating application resources
resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    module.eks,
    module.addons
  ]

  create_duration = "30s"
}

# Application Module
module "application" {
  source = "./modules/application"

  project_name = var.project_name
  app_name     = var.app_name
  namespace    = var.namespace
  image_tag    = var.image_tag
  replicas     = var.game_replicas

  container_port  = var.container_port
  service_port    = var.service_port
  container_cpu_limit    = var.container_cpu_limit
  container_memory_limit = var.container_memory_limit
  container_cpu_request  = var.container_cpu_request
  container_memory_request = var.container_memory_request

  depends_on = [time_sleep.wait_for_cluster]

  tags = local.common_tags
}

# Local values for common tags
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}
