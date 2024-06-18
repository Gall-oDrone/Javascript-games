variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

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

variable "service_name" {
  description = "The name of the Kubernetes service"
  type        = string
}
