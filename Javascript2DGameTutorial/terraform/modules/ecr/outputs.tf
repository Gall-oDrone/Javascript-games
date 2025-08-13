# modules/ecr/outputs.tf - ECR Module Outputs

output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "The name of the repository"
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.this.registry_id
}

output "repository_uri" {
  description = "The URI of the repository"
  value       = aws_ecr_repository.this.repository_url
}

# Useful for CI/CD pipelines
output "docker_login_command" {
  description = "Docker login command for this ECR registry"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}"
  sensitive   = false
}

output "docker_push_commands" {
  description = "Example commands to build, tag, and push Docker image"
  value = {
    build = "docker build -t ${var.repository_name} ."
    tag   = "docker tag ${var.repository_name}:latest ${aws_ecr_repository.this.repository_url}:latest"
    push  = "docker push ${aws_ecr_repository.this.repository_url}:latest"
  }
}

# Data source to get current region
data "aws_region" "current" {}