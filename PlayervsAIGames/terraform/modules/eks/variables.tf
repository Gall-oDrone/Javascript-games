variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "The name of the node group"
  type        = string
}

variable "desired_capacity" {
  description = "The desired number of nodes"
  type        = number
}

variable "max_capacity" {
  description = "The maximum number of nodes"
  type        = number
}

variable "min_capacity" {
  description = "The minimum number of nodes"
  type        = number
}

variable "subnet_ids" {
  description = "The subnet IDs for the EKS cluster"
  type        = list(string)
}
