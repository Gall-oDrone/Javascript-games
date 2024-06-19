provider "aws" {
    region = var.aws_region
}

module "eks" {
    source = "./modules/eks"
    cluster_name = var.cluster_name
    node_group_name = var.node.group_name
    desired_capacity = var.desired_capacity
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
}

module "nginx" {
    source = "./modules/nginx"
    cluster_name = module.eks.cluster_name
    vpc_id = module.eks.vpc_id
    subnets_ids = module.eks.subnets_ids
    service_name = var.service_name
}