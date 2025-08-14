# Development Environment Configuration - Modern EKS Pattern
environment = "dev"
aws_region  = "us-west-2"

# Project Configuration
project_name = "javascript-2d-game"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# EKS Cluster Configuration
cluster_name        = "javascript-2d-game-dev"
kubernetes_version  = "1.33"  # Use supported version
authentication_mode = "API_AND_CONFIG_MAP"  # Modern authentication

# Application Configuration
game_replicas = 2

# Node Group Configuration
node_group_instance_types = ["t3.medium"]
node_group_desired_size   = 2
node_group_min_size       = 2  # Minimum 2 for HA
node_group_max_size       = 4
node_group_disk_size      = 50
node_group_ami_type       = "AL2023_x86_64_STANDARD"  # For K8s 1.33

# EKS Blueprints Addons
enable_aws_load_balancer_controller = true
enable_metrics_server               = true
enable_karpenter                   = false  # Advanced autoscaling - optional
enable_aws_cloudwatch_metrics      = false  # Can enable for production
enable_cert_manager                = false  # For TLS management
aws_load_balancer_controller_chart_version = "1.6.2"
metrics_server_chart_version               = "6.4.1"

# Autoscaling Configuration
enable_autoscaling = true
hpa_min_replicas   = 2
hpa_max_replicas   = 6
hpa_cpu_target     = 70
hpa_memory_target  = 80

# Container Resources (Development - Moderate resources)
container_cpu_limit      = "500m"
container_memory_limit   = "512Mi"
container_cpu_request    = "250m"
container_memory_request = "256Mi"

# Monitoring and Security
enable_monitoring    = true
enable_backup        = false
enable_kms_encryption = true
kms_key_deletion_window = 7

# Tags
tags = {
  Environment = "dev"
  Application = "javascript-2d-game"
  Component   = "game"
  ManagedBy   = "terraform"
  Owner       = "game-dev-team"
  CostCenter  = "development"
}