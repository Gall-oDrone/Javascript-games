variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  type        = string
}

variable "cluster_addons" {
  description = "Map of EKS cluster addons"
  type        = map(any)
  default = {
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
    }
  }
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_config" {
  description = "AWS Load Balancer Controller configuration"
  type        = map(any)
  default = {
    chart_version = "1.6.2"
    set = [
      {
        name  = "enableWebhook"
        value = "true"
      },
      {
        name  = "enableWebhookSecret"
        value = "true"
      }
    ]
  }
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "enable_aws_cloudwatch_metrics" {
  description = "Enable AWS CloudWatch Metrics"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager"
  type        = bool
  default     = false
}

variable "enable_karpenter" {
  description = "Enable Karpenter"
  type        = bool
  default     = false
}

variable "karpenter_config" {
  description = "Karpenter configuration"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
