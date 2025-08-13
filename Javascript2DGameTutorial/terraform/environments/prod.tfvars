# Production Environment Configuration - Modern EKS Pattern
environment = "prod"
aws_region  = "us-west-2"

# EKS Cluster Configuration
cluster_name        = "javascript-2d-game-prod"
kubernetes_version  = "1.33"  # Use stable version for production
authentication_mode = "API_AND_CONFIG_MAP"  # Modern authentication

# Application Configuration
game_replicas = 3

# Node Group Configuration - Production sized
node_group_instance_types = ["t3.large"]  # Larger instances for production
node_group_desired_size   = 3
node_group_min_size       = 3  # Higher minimum for HA
node_group_max_size       = 10
node_group_disk_size      = 100  # More disk for production
node_group_ami_type       = "AL2023_x86_64_STANDARD"

# EKS Blueprints Addons - More features for production
enable_aws_load_balancer_controller = true
enable_metrics_server               = true
enable_karpenter                   = true   # Advanced autoscaling for production
enable_aws_cloudwatch_metrics      = true   # Production monitoring
enable_cert_manager                = true   # TLS management for production
aws_load_balancer_controller_chart_version = "1.6.2"

# Autoscaling Configuration - Production scale
enable_autoscaling = true
hpa_min_replicas   = 3
hpa_max_replicas   = 15
hpa_cpu_target     = 70
hpa_memory_target  = 80

# Container Resources (Production - Higher resources)
container_cpu_limit      = "1000m"
container_memory_limit   = "1Gi"
container_cpu_request    = "500m"
container_memory_request = "512Mi"

# Domain and SSL (Configure for production)
# domain_name = "game.example.com"
# certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-cert-id"

# Monitoring and Security - All enabled for production
enable_monitoring    = true
enable_backup        = true
enable_kms_encryption = true
kms_key_deletion_window = 30  # Longer window for production

# Tags
tags = {
  Environment = "prod"
  Application = "javascript-2d-game"
  Component   = "game"
  ManagedBy   = "terraform"
  Owner       = "game-dev-team"
  CostCenter  = "production"
  Compliance  = "required"
  Criticality = "high"
}