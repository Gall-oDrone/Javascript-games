# modules/ecr/variables.tf - ECR Module Variables

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "JSON policy to apply to the repository"
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for the repository"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep in the repository (0 = unlimited)"
  type        = number
  default     = 30
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which to expire untagged images (0 = never expire)"
  type        = number
  default     = 7
}

variable "protected_tags" {
  description = "List of tag prefixes to protect from lifecycle policy"
  type        = list(string)
  default     = ["prod", "release", "stable"]
}

variable "protected_tag_count" {
  description = "Number of images to keep for protected tags"
  type        = number
  default     = 10
}

variable "enable_pull_through_cache" {
  description = "Enable pull through cache for Docker Hub"
  type        = bool
  default     = false
}

variable "enable_registry_scanning" {
  description = "Enable enhanced registry scanning"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}