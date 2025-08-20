# Development Environment Variables
# This file declares all variables used by the dev environment

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "javascript-2d-game"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "game-dev-team"
}

variable "enable_prometheus_stack" {
  description = "Enable Prometheus, Grafana, and Alertmanager stack"
  type        = bool
  default     = false
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


# EKS Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "javascript-2d-game-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
  validation {
    condition     = contains(["1.28", "1.29", "1.30", "1.31", "1.33"], var.kubernetes_version)
    error_message = "Kubernetes version must be one of: 1.28, 1.29, 1.30, 1.31, 1.33"
  }
}

# Authentication Mode for Modern EKS
variable "authentication_mode" {
  description = "EKS authentication mode (API, CONFIG_MAP, or API_AND_CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
  validation {
    condition     = contains(["API", "CONFIG_MAP", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "Authentication mode must be one of: API, CONFIG_MAP, API_AND_CONFIG_MAP"
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Node Group Configuration
variable "node_group_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "node_group_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

variable "node_group_ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
  validation {
    condition     = contains(["AL2_x86_64", "AL2_ARM_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD"], var.node_group_ami_type)
    error_message = "AMI type must be one of: AL2_x86_64, AL2_ARM_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD"
  }
}

# Node Groups Map (for EKS module)
variable "node_groups" {
  description = "Map of EKS managed node groups"
  type        = map(any)
  default     = {}
}

# EKS Blueprints Addons Configuration
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller addon"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server for HPA"
  type        = bool
  default     = true
}

variable "enable_karpenter" {
  description = "Enable Karpenter for advanced node autoscaling"
  type        = bool
  default     = false
}

variable "enable_aws_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics addon"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for TLS certificate management"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.6.2"
}

variable "metrics_server_chart_version" {
  description = "Chart version for Metrics Server"
  type        = string
  default     = "6.2.12"
}

# Application Configuration
variable "game_replicas" {
  description = "Number of game replicas to deploy"
  type        = number
  default     = 2
  validation {
    condition     = var.game_replicas >= 1 && var.game_replicas <= 10
    error_message = "Game replicas must be between 1 and 10."
  }
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_cpu_target" {
  description = "CPU target percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "Memory target percentage for HPA"
  type        = number
  default     = 80
}

# Container Resources
variable "container_cpu_limit" {
  description = "CPU limit for game container"
  type        = string
  default     = "500m"
}

variable "container_memory_limit" {
  description = "Memory limit for game container"
  type        = string
  default     = "512Mi"
}

variable "container_cpu_request" {
  description = "CPU request for game container"
  type        = string
  default     = "250m"
}

variable "container_memory_request" {
  description = "Memory request for game container"
  type        = string
  default     = "256Mi"
}

# Domain and SSL Configuration
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for HTTPS (optional)"
  type        = string
  default     = ""
}

# Monitoring and Logging
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and logging"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable EKS cluster backup"
  type        = bool
  default     = false
}

# KMS Configuration
variable "enable_kms_encryption" {
  description = "Enable KMS encryption for EKS secrets"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Application = "javascript-2d-game"
    Component   = "game"
    ManagedBy   = "terraform"
  }
}
