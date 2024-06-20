output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "vpc_id" {
  value = aws_eks_cluster.this.vpc_config[0].vpc_id
}

output "subnet_ids" {
  value = aws_eks_cluster.this.vpc_config[0].subnet_ids
}
