# Development Environment Configuration
environment = "dev"
aws_region  = "us-west-2"

# EKS Cluster Configuration
cluster_name        = "javascript-2d-game-dev"
kubernetes_version  = "1.28"
game_replicas       = 1

# Node Group Configuration
node_group_instance_types = ["t3.medium"]
node_group_desired_size   = 1
node_group_min_size       = 1
node_group_max_size       = 3

# Autoscaling Configuration
enable_autoscaling = true
hpa_min_replicas   = 1
hpa_max_replicas   = 3
hpa_cpu_target     = 70
hpa_memory_target  = 80

# Container Resources (Development - Lower resources)
container_cpu_limit    = "300m"
container_memory_limit = "384Mi"
container_cpu_request  = "150m"
container_memory_request = "192Mi"

# Monitoring and Backup
enable_monitoring = true
enable_backup     = false

# Tags
tags = {
  Environment = "dev"
  Application = "javascript-2d-game"
  Component   = "game"
  ManagedBy   = "terraform"
  Owner       = "game-dev-team"
} 