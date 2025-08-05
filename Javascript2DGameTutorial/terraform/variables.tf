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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "javascript-2d-game-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Note: Subnet CIDRs are now generated dynamically based on available AZs
# This ensures compatibility across different AWS regions with varying AZ counts
# Private subnets: 10.0.1.0/24, 10.0.2.0/24, etc. (one per AZ)
# Public subnets: 10.0.101.0/24, 10.0.102.0/24, etc. (one per AZ)

variable "game_replicas" {
  description = "Number of game replicas to deploy"
  type        = number
  default     = 2
  validation {
    condition     = var.game_replicas >= 1 && var.game_replicas <= 10
    error_message = "Game replicas must be between 1 and 10."
  }
}

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
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 5
}

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 1
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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Application = "javascript-2d-game"
    Component   = "game"
    ManagedBy   = "terraform"
  }
} 