# modules/vpc/variables.tf - VPC Module Variables

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging (optional)"
  type        = string
  default     = ""
}

variable "max_azs" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3
}

variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true to provision one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Should be true to provision a VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_s3_endpoint" {
  description = "Should be true to provision an S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_endpoint" {
  description = "Should be true to provision ECR VPC endpoints"
  type        = bool
  default     = false
}

variable "enable_eks_endpoint" {
  description = "Should be true to provision EKS VPC endpoint"
  type        = bool
  default     = false
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}