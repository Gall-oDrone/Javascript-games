# modules/vpc/main.tf - VPC Module

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = min(length(data.aws_availability_zones.available.names), var.max_azs)
  
  # Generate subnet CIDRs dynamically based on available AZs
  private_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.cidr, 8, i + 1)
  ]
  
  public_subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.cidr, 8, i + 100)
  ]
  
  # Use only the required number of AZs
  azs = slice(data.aws_availability_zones.available.names, 0, local.az_count)
}

# VPC Module from terraform-aws-modules
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  
  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPN Gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  # Subnet tagging for EKS
  public_subnet_tags = merge(
    var.public_subnet_tags,
    var.cluster_name != "" ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    } : {}
  )

  private_subnet_tags = merge(
    var.private_subnet_tags,
    var.cluster_name != "" ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    } : {}
  )

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# VPC Endpoints for AWS services (optional)
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  route_table_ids = concat(
    module.vpc.private_route_table_ids,
    module.vpc.public_route_table_ids
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-s3-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoint ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids = module.vpc.private_subnets

  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-ecr-api-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoint ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids = module.vpc.private_subnets

  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-ecr-dkr-endpoint"
      Environment = var.environment
    }
  )
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = (var.enable_ecr_endpoint || var.enable_eks_endpoint) ? 1 : 0

  name_prefix = "${var.name}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-vpc-endpoints-sg"
      Environment = var.environment
    }
  )
}

# EKS VPC endpoints
resource "aws_vpc_endpoint" "eks" {
  count = var.enable_eks_endpoint ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids = module.vpc.private_subnets

  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-eks-endpoint"
      Environment = var.environment
    }
  )
}

data "aws_region" "current" {}