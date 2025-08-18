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

# Prometheus Stack Configuration
variable "enable_prometheus_stack" {
  description = "Enable Prometheus, Grafana, and Alertmanager stack"
  type        = bool
  default     = false
}

variable "prometheus_stack_chart_version" {
  description = "Chart version for kube-prometheus-stack"
  type        = string
  default     = "51.3.0"
}

variable "prometheus_stack_values" {
  description = "Additional values for Prometheus stack Helm chart"
  type        = any
  default     = {}
}

# Grafana specific configuration
variable "enable_grafana_ingress" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_hostname" {
  description = "Hostname for Grafana ingress (e.g., grafana.example.com)"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (leave empty to generate random)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana data"
  type        = string
  default     = "5Gi"
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