variable "project_name" {
  description = "Name of the project"
  type        = string
}

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

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "service_port" {
  description = "Port the service exposes"
  type        = number
  default     = 80
}

variable "container_cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "500m"
}

variable "container_memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "container_cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "250m"
}

variable "container_memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "256Mi"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
