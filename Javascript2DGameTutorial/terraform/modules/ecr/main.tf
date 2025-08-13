# modules/ecr/main.tf - ECR Repository Module

# ECR Repository for Docker images
resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key        = var.kms_key_arn
  }

  tags = merge(
    var.tags,
    {
      Name        = var.repository_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ECR Repository Policy (optional)
resource "aws_ecr_repository_policy" "this" {
  count = var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = concat(
      # Keep last N images
      var.max_image_count > 0 ? [{
        rulePriority = 10
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }] : [],
      
      # Remove untagged images after N days
      var.untagged_image_expiry_days > 0 ? [{
        rulePriority = 20
        description  = "Remove untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = var.untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      }] : [],
      
      # Keep only N tagged images with specific prefixes
      length(var.protected_tags) > 0 ? [
        for idx, tag in var.protected_tags : {
          rulePriority = 30 + idx
          description  = "Protect images with tag ${tag}"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = [tag]
            countType     = "imageCountMoreThan"
            countNumber   = var.protected_tag_count
          }
          action = {
            type = "expire"
          }
        }
      ] : []
    )
  })
}

# Pull through cache rule (optional, for Docker Hub rate limiting)
resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  count = var.enable_pull_through_cache ? 1 : 0

  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
}

# Registry scanning configuration
resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.enable_registry_scanning ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = var.repository_name
      filter_type = "WILDCARD"
    }
  }
}