# EKS Addons Module
# Following AWS Blueprints best practices

# EKS Cluster Addons using EKS native addons
resource "aws_eks_addon" "addons" {
  for_each = var.cluster_addons

  cluster_name = var.cluster_name
  addon_name   = each.key

  addon_version = lookup(each.value, "addon_version", null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", "OVERWRITE")
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", "OVERWRITE")

  configuration_values = lookup(each.value, "configuration_values", null)

  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = var.tags
}

# EKS Blueprints Addons for additional components
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  # AWS Load Balancer Controller
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller = var.aws_load_balancer_controller_config

  # Metrics Server for HPA
  enable_metrics_server = var.enable_metrics_server

  tags = var.tags
}
