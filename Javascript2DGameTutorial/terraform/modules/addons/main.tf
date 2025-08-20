# modules/addons/main.tf - EKS Addons Module Implementation

# IAM Role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}

# Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa[0].iam_role_arn
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["eks.amazonaws.com/role-arn"]
    ]
  }

  depends_on = [module.aws_load_balancer_controller_irsa]

  # Add provider configuration to ensure proper authentication
  provider = kubernetes
}

# AWS Load Balancer Controller Helm Release
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.aws_load_balancer_controller_chart_version

  timeout = 600  # 10 minutes timeout

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller[0].metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "enableWebhook"
    value = "true"
  }

  set {
    name  = "enableWebhookSecret"
    value = "true"
  }

  # Merge additional values if provided
  dynamic "set" {
    for_each = try(var.aws_load_balancer_controller_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller
  ]

  lifecycle {
    ignore_changes = [
      set
    ]
  }

  # Add provider configuration to ensure proper authentication
  provider = helm
}

# Metrics Server Helm Release
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_chart_version

  timeout = 500

  values = [
    yamlencode({
      args = [
        "--secure-port=4443",
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      ],
      containerPorts = {
        https = 4443
      },
      service = {
        ports = {
          https = 443
        },
        targetPorts = {
          https = 4443
        }
      }
    })
  ]

  dynamic "set" {
    for_each = try(var.metrics_server_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  lifecycle {
    ignore_changes = [
      values,
      set
    ]
  }

  # Add provider configuration to ensure proper authentication
  provider = helm
}

# Generate random password if not provided
resource "random_password" "grafana_admin" {
  count   = var.enable_prometheus_stack && var.grafana_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Prometheus & Grafana Stack
resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = var.prometheus_stack_chart_version

  create_namespace = true
  timeout         = 600

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          retention = "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                storageClassName = "gp3" # Changed from gp2 to gp3
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        enabled = true
        defaultDashboardsEnabled = true
        adminPassword = var.grafana_admin_password != "" ? var.grafana_admin_password : try(random_password.grafana_admin[0].result, "admin")
        persistence = {
          enabled = true
          size    = var.grafana_storage_size
          storageClassName = "gp3"
        }
        ingress = var.enable_grafana_ingress ? {
          enabled = true
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
          }
          hosts = var.grafana_hostname != "" ? [var.grafana_hostname] : []
          paths = ["/"]
        } : {
          enabled = false
          ingressClassName = ""
          annotations = {}
          hosts = []
          paths = []
        }
        service = {
          type = var.enable_grafana_ingress ? "ClusterIP" : "LoadBalancer"
        }
      }
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                storageClassName = "gp3"
                resources = {
                  requests = {
                    storage = "2Gi"
                  }
                }
              }
            }
          }
        }
      }
      # Disable components that overlap with metrics-server
      kubeStateMetrics = {
        enabled = true  # This is complementary, not overlapping
      }
      nodeExporter = {
        enabled = true  # For node-level metrics
      }
      # Service monitors for scraping metrics
      defaultRules = {
        create = true
      }
      kubeApiServer = {
        enabled = true
      }
      kubeControllerManager = {
        enabled = false  # Often not accessible in EKS
      }
      kubeScheduler = {
        enabled = false  # Often not accessible in EKS
      }
      kubeEtcd = {
        enabled = false  # Not accessible in EKS
      }
    })
  ]

  dynamic "set" {
    for_each = try(var.prometheus_stack_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    helm_release.metrics_server
  ]
}

# IAM Role for Karpenter
module "karpenter_irsa" {
  count = var.enable_karpenter ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-karpenter"

  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = var.cluster_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  tags = var.tags
}

# Karpenter Helm Release
resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_chart_version

  timeout = 600  # 10 minutes timeout

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa[0].iam_role_arn
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  }

  set {
    name  = "settings.interruptionQueueName"
    value = var.cluster_name
  }

  # Merge additional values if provided
  dynamic "set" {
    for_each = try(var.karpenter_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.karpenter_irsa
  ]

  lifecycle {
    ignore_changes = [
      set
    ]
  }
}

# Cert Manager Helm Release
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = var.cert_manager_chart_version

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  # Merge additional values if provided
  dynamic "set" {
    for_each = try(var.cert_manager_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }

  lifecycle {
    ignore_changes = [
      values,
      set
    ]
  }
}

# CloudWatch Container Insights - Fluent Bit
resource "aws_cloudwatch_log_group" "container_insights" {
  count = var.enable_aws_cloudwatch_metrics ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/container-insights"
  retention_in_days = 7
  
  tags = var.tags
}

# IAM Role for CloudWatch Container Insights
module "cloudwatch_container_insights_irsa" {
  count = var.enable_aws_cloudwatch_metrics ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-cloudwatch-container-insights"

  role_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["amazon-cloudwatch:cloudwatch-agent", "amazon-cloudwatch:fluent-bit"]
    }
  }

  tags = var.tags
}