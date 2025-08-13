# modules/addons/main.tf - EKS Addons Module Implementation

# EKS Native Addons
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name = var.cluster_name
  addon_name   = each.key

  addon_version            = each.value.addon_version
  configuration_values     = each.value.configuration_values
  preserve                 = each.value.preserve
  resolve_conflicts        = each.value.resolve_conflicts
  service_account_role_arn = each.value.service_account_role_arn

  tags = var.tags
}

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
}

# AWS Load Balancer Controller Helm Release
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.aws_load_balancer_controller_chart_version

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
}

# Metrics Server Helm Release
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_chart_version

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  # Merge additional values if provided
  dynamic "set" {
    for_each = try(var.metrics_server_values, {})
    content {
      name  = set.key
      value = set.value
    }
  }
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