locals {
  tags = {
    Name        = var.cluster_name
    Environment = "dev"
  }
}
