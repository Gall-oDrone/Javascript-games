locals {
  name   = var.cluster_name
  region = var.aws_region
  # Trn1 and Inf2 instances are available in specific AZs in us-east-1,
  # us-east-2, and us-west-2. For Trn1, the first AZ id (below) should be used.
  az_mapping = {
    "us-east-1" = ["use1-az6", "use1-az5"]
  }
  azs = local.az_mapping[var.aws_region]
  tags = {
    Name        = var.cluster_name
    Environment = "dev"
  }
}
