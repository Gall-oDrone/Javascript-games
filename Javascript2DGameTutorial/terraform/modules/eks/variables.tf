variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
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

variable "authentication_mode" {
  description = "EKS authentication mode (API, CONFIG_MAP, or API_AND_CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
  validation {
    condition     = contains(["API", "CONFIG_MAP", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "Authentication mode must be one of: API, CONFIG_MAP, API_AND_CONFIG_MAP"
  }
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS managed node groups"
  type        = map(any)
  default = {
    general = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      ami_type = "AL2023_x86_64_STANDARD"
      platform = "linux"
      
      disk_size = 50
      
      create_iam_role = true
      iam_role_name   = "eks-node-group-role"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
