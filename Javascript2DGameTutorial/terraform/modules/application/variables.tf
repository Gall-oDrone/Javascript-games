# modules/application/variables.tf - Application Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Application configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "javascript-2d-game"
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "javascript-2d-game"
}

variable "game_replicas" {
  description = "Number of game replicas"
  type        = number
  default     = 2
}

variable "container_cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "container_memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"
}

variable "container_cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "250m"
}

variable "container_memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "256Mi"
}

# Autoscaling configuration
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
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

# Service configuration
variable "service_type" {
  description = "Type of Kubernetes service"
  type        = string
  default     = "LoadBalancer"
}

variable "service_port" {
  description = "Port for the service"
  type        = number
  default     = 80
}

variable "container_port" {
  description = "Port that the container listens on"
  type        = number
  default     = 80
}

# Ingress configuration
variable "enable_ingress" {
  description = "Enable ingress for the application"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "alb"
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

# Health check configuration
variable "liveness_probe_path" {
  description = "Path for liveness probe"
  type        = string
  default     = "/"
}

variable "readiness_probe_path" {
  description = "Path for readiness probe"
  type        = string
  default     = "/"
}

variable "liveness_probe_initial_delay" {
  description = "Initial delay for liveness probe in seconds"
  type        = number
  default     = 30
}

variable "readiness_probe_initial_delay" {
  description = "Initial delay for readiness probe in seconds"
  type        = number
  default     = 5
}

# Image configuration
variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}