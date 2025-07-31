# Production Environment Configuration
environment = "prod"
aws_region  = "us-west-2"

# EKS Cluster Configuration
cluster_name        = "javascript-2d-game-prod"
kubernetes_version  = "1.28"
game_replicas       = 3

# Node Group Configuration
node_group_instance_types = ["t3.large"]
node_group_desired_size   = 3
node_group_min_size       = 2
node_group_max_size       = 10

# Autoscaling Configuration
enable_autoscaling = true
hpa_min_replicas   = 2
hpa_max_replicas   = 10
hpa_cpu_target     = 70
hpa_memory_target  = 80

# Container Resources (Production - Higher resources)
container_cpu_limit    = "1000m"
container_memory_limit = "1Gi"
container_cpu_request  = "500m"
container_memory_request = "512Mi"

# Monitoring and Backup
enable_monitoring = true
enable_backup     = true

# Domain and SSL (Configure these for production)
# domain_name = "your-domain.com"
# certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-cert-id"

# Tags
tags = {
  Environment = "prod"
  Application = "javascript-2d-game"
  Component   = "game"
  ManagedBy   = "terraform"
  Owner       = "game-dev-team"
} 