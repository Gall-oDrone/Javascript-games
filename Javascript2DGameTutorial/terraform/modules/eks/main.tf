# EKS Module for Kubernetes Cluster
# Following AWS Blueprints best practices

# KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Use Access Entry API instead of aws-auth ConfigMap
  authentication_mode = var.authentication_mode
  
  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Don't manage aws-auth directly
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  # Enable IRSA
  enable_irsa = true

  # KMS encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = var.node_groups

  tags = var.tags
}

# IRSA for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}
