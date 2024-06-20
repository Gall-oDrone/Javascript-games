output "service_url" {
  value = kubernetes_service.nginx.status[0].load_balancer.ingress[0].hostname
}
