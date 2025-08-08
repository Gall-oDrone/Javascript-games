terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket = "javascript-2d-game-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "javascript-2d-game"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Configure Kubernetes Provider (for EKS)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data sources
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for dynamic subnet configuration
locals {
  az_count = length(data.aws_availability_zones.available.names)
  
  # Generate subnet CIDRs dynamically based on available AZs
  private_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]
  
  public_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 100)
  ]
  
  # Validation
  required_azs = 2
}

# Validate AZ count
resource "null_resource" "az_validation" {
  count = local.az_count >= local.required_azs ? 0 : "ERROR: Region ${var.aws_region} has only ${local.az_count} AZs, but ${local.required_azs} are required"
}

# VPC and Networking
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  # Use all available AZs and dynamic CIDRs
  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable OIDC Provider for IRSA
  enable_irsa = true

  # Enable cluster encryption with KMS
  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  # Configure KMS key deletion window to 7 days
  kms_key_deletion_window_in_days = 7
  
  # Let the module create the aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = false

  eks_managed_node_groups = {
    general = {
      desired_size = var.node_group_desired_size
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size

      instance_types = var.node_group_instance_types
      capacity_type  = "ON_DEMAND"
      
      # For Kubernetes 1.33, we can use AL2023
      ami_type = "AL2023_x86_64_STANDARD"
      
      # Ensure the node group has the correct IAM policies
      iam_role_additional_policies = {
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy                = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        Environment = var.environment
        Project     = var.project_name
      }

      tags = {
        ExtraTag = "eks-node-group"
        env     = var.environment
      }
      
      # Add taints if needed
      taints = []
      
      # Ensure proper disk size
      disk_size = 50
    }
  }

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "game" {
  name                 = "${var.project_name}-game"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "game" {
  repository = aws_ecr_repository.game.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# IAM Policy for AWS Load Balancer Controller
module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  depends_on = [module.eks]
  
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa_role.iam_role_arn
    }
  }
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  depends_on = [
    module.eks,
    module.load_balancer_controller_irsa_role,
    kubernetes_service_account.aws_load_balancer_controller
  ]
  
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.0"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
}

# Kubernetes namespace for the game
resource "kubernetes_namespace" "game" {
  depends_on = [module.eks]

  metadata {
    name = "javascript-2d-game"
    labels = {
      name = "javascript-2d-game"
    }
  }
}

# Kubernetes deployment for the game
resource "kubernetes_deployment" "game" {
  depends_on = [module.eks, kubernetes_namespace.game]

  metadata {
    name      = "javascript-2d-game"
    namespace = kubernetes_namespace.game.metadata[0].name
    labels = {
      app = "javascript-2d-game"
    }
  }

  spec {
    replicas = var.game_replicas

    selector {
      match_labels = {
        app = "javascript-2d-game"
      }
    }

    template {
      metadata {
        labels = {
          app = "javascript-2d-game"
        }
      }

      spec {
        container {
          image = "${aws_ecr_repository.game.repository_url}:latest"
          name  = "javascript-2d-game"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = var.container_cpu_limit
              memory = var.container_memory_limit
            }
            requests = {
              cpu    = var.container_cpu_request
              memory = var.container_memory_request
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Kubernetes service
resource "kubernetes_service" "game" {
  depends_on = [module.eks, kubernetes_namespace.game]

  metadata {
    name      = "javascript-2d-game-service"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = "javascript-2d-game"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# Ingress for the game
resource "kubernetes_ingress_v1" "game" {
  depends_on = [
    module.eks,
    kubernetes_namespace.game,
    kubernetes_service.game,
    helm_release.aws_load_balancer_controller
  ]

  metadata {
    name      = "javascript-2d-game-ingress"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
      "alb.ingress.kubernetes.io/success-codes"        = "200-399"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.game.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "game" {
  depends_on = [module.eks, kubernetes_namespace.game, kubernetes_deployment.game]

  metadata {
    name      = "javascript-2d-game-hpa"
    namespace = kubernetes_namespace.game.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.game.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }
}

# Outputs
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

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.game.repository_url
}

output "load_balancer_hostname" {
  description = "The hostname of the load balancer"
  value       = kubernetes_service.game.status[0].load_balancer[0].ingress[0].hostname
}

# VPC and networking outputs for debugging
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

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "az_count" {
  description = "Number of availability zones"
  value       = local.az_count
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  value       = local.private_subnet_cidrs
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  value       = local.public_subnet_cidrs
}