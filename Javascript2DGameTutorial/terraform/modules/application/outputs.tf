output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.ecr_repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = var.ecr_repository_url
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = try(kubernetes_service.game.status[0].load_balancer[0].ingress[0].hostname, "")
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used for HTTPS"
  value       = var.acm_certificate_arn
}
