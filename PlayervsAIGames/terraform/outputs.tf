output "cluster_name" {
  value = module.eks.cluster_name
}

output "nginx_service_url" {
  value = module.nginx.service_url
}
