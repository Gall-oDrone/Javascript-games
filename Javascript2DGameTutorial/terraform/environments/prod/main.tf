# Production Environment Configuration
# Following AWS Blueprints best practices

terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket = "javascript-2d-game-terraform-state-prod"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "javascript-2d-game"
      Owner       = "game-dev-team"
      ManagedBy   = "terraform"
    }
  }
}

# Main module configuration
module "javascript_2d_game" {
  source = "../../"

  # Environment configuration
  environment = "prod"
  aws_region  = "us-west-2"

  # Project configuration
  project_name = "javascript-2d-game"
  owner        = "game-dev-team"

  # EKS Cluster configuration
  cluster_name       = "javascript-2d-game-cluster-prod"
  kubernetes_version = "1.33"
  authentication_mode = "API_AND_CONFIG_MAP"

  # VPC configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Node groups configuration
  node_groups = {
    general = {
      min_size     = 2
      max_size     = 6
      desired_size = 3

      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "ON_DEMAND"
      
      ami_type = "AL2023_x86_64_STANDARD"
      platform = "linux"
      
      disk_size = 100
      
      create_iam_role = true
      iam_role_name   = "eks-node-group-role-prod"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        Environment = "prod"
        Project     = "javascript-2d-game"
      }

      tags = {
        Environment = "prod"
        Project     = "javascript-2d-game"
      }
    }
  }

  # Application configuration
  app_name = "javascript-2d-game"
  namespace = "javascript-2d-game-prod"
  image_tag = "latest"
  game_replicas = 3

  container_port  = 80
  service_port    = 80
  container_cpu_limit    = "1000m"
  container_memory_limit = "1Gi"
  container_cpu_request  = "500m"
  container_memory_request = "512Mi"
}
