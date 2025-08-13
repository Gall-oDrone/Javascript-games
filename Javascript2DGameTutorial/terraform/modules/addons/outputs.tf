# modules/addons/outputs.tf - Outputs for the addons module

output "aws_load_balancer_controller_enabled" {
  description = "Whether AWS Load Balancer Controller is enabled"
  value       = var.enable_aws_load_balancer_controller
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = try(module.aws_load_balancer_controller_irsa[0].iam_role_arn, null)
}

output "metrics_server_enabled" {
  description = "Whether Metrics Server is enabled"
  value       = var.enable_metrics_server
}

output "karpenter_enabled" {
  description = "Whether Karpenter is enabled"
  value       = var.enable_karpenter
}

output "karpenter_role_arn" {
  description = "IAM role ARN for Karpenter"
  value       = try(module.karpenter_irsa[0].iam_role_arn, null)
}

output "cert_manager_enabled" {
  description = "Whether cert-manager is enabled"
  value       = var.enable_cert_manager
}

output "cloudwatch_metrics_enabled" {
  description = "Whether CloudWatch Container Insights is enabled"
  value       = var.enable_aws_cloudwatch_metrics
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for Container Insights"
  value       = try(aws_cloudwatch_log_group.container_insights[0].name, null)
}

output "installed_addons" {
  description = "Summary of installed addons"
  value = {
    aws_load_balancer_controller = var.enable_aws_load_balancer_controller
    metrics_server               = var.enable_metrics_server
    karpenter                   = var.enable_karpenter
    cert_manager                = var.enable_cert_manager
    cloudwatch_metrics          = var.enable_aws_cloudwatch_metrics
  }
}