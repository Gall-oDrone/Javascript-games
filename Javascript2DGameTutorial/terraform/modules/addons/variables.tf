# modules/addons/variables.tf - Fixed version without function calls in defaults

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# EKS Native Addons Configuration
variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    most_recent          = optional(bool, true)
    addon_version        = optional(string, null)
    configuration_values = optional(string, null)  # Should be a JSON string
    preserve             = optional(bool, true)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string, null)
  }))
  default = {}
}

# AWS Load Balancer Controller Configuration
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.6.2"
}

variable "aws_load_balancer_controller_values" {
  description = "Additional values for AWS Load Balancer Controller Helm chart"
  type        = any
  default     = {}
}

# Metrics Server Configuration
variable "enable_metrics_server" {
  description = "Enable Metrics Server for HPA"
  type        = bool
  default     = true
}

variable "metrics_server_chart_version" {
  description = "Chart version for Metrics Server"
  type        = string
  default     = "3.11.0"
}

variable "metrics_server_values" {
  description = "Additional values for Metrics Server Helm chart"
  type        = any
  default     = {}
}

# Karpenter Configuration
variable "enable_karpenter" {
  description = "Enable Karpenter for node autoscaling"
  type        = bool
  default     = false
}

variable "karpenter_chart_version" {
  description = "Chart version for Karpenter"
  type        = string
  default     = "v0.31.0"
}

variable "karpenter_values" {
  description = "Additional values for Karpenter Helm chart"
  type        = any
  default     = {}
}

# Cert Manager Configuration
variable "enable_cert_manager" {
  description = "Enable cert-manager for TLS certificate management"
  type        = bool
  default     = false
}

variable "cert_manager_chart_version" {
  description = "Chart version for cert-manager"
  type        = string
  default     = "v1.13.0"
}

variable "cert_manager_values" {
  description = "Additional values for cert-manager Helm chart"
  type        = any
  default     = {}
}

# CloudWatch Metrics Configuration
variable "enable_aws_cloudwatch_metrics" {
  description = "Enable CloudWatch Container Insights metrics"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}