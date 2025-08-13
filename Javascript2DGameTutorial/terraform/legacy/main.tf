# Modern EKS configuration following AWS Blueprints patterns

# EKS Cluster with Access Entry API
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"  # Use version 20+ for Access Entry API support

  cluster_name                   = var.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Use Access Entry API instead of aws-auth ConfigMap
  authentication_mode = "API_AND_CONFIG_MAP"
  
  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Don't manage aws-auth directly
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  # Enable IRSA
  enable_irsa = true

  # KMS encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      ami_type = "AL2_x86_64"
      platform = "linux"
      
      disk_size = 50
      
      # Use launch template
      use_custom_launch_template = false
      
      # Let the module handle IAM
      create_iam_role = true
      iam_role_name   = "${var.cluster_name}-node-group-role"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        Environment = var.environment
        Project     = var.project_name
      }

      tags = {
        Environment = var.environment
        Project     = var.project_name
      }
    }
  }

  # Cluster addons using EKS native addons
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
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create KMS key for EKS
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.cluster_name}-eks-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# IRSA for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Use EKS Blueprints Addons module for additional components
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
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

  # Metrics Server for HPA
  enable_metrics_server = true

  # Optional: Add more addons as needed
  # enable_karpenter = true
  # enable_aws_cloudwatch_metrics = true
  # enable_cert_manager = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Wait for the cluster to be ready before creating k8s resources
resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    module.eks,
    module.eks_blueprints_addons
  ]

  create_duration = "30s"
}

# Now create your application resources
resource "kubernetes_namespace" "game" {
  depends_on = [time_sleep.wait_for_cluster]

  metadata {
    name = "javascript-2d-game"
    labels = {
      name = "javascript-2d-game"
    }
  }
}

resource "kubernetes_deployment" "game" {
  depends_on = [kubernetes_namespace.game]

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

resource "kubernetes_service" "game" {
  depends_on = [kubernetes_namespace.game]

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

# Ingress with proper dependency on ALB controller
resource "kubernetes_ingress_v1" "game" {
  depends_on = [
    kubernetes_service.game,
    module.eks_blueprints_addons,
    time_sleep.wait_for_cluster
  ]

  metadata {
    name      = "javascript-2d-game-ingress"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = "alb"
    
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