terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "aws" {
  source = "../../modules/aws"

  project_name         = var.project_name
  aws_region           = var.aws_region
  vpc_cidr             = var.aws_vpc_cidr
  public_subnet_cidrs  = var.aws_public_subnet_cidrs
  private_subnet_cidrs = var.aws_private_subnet_cidrs

  kubernetes_version  = var.aws_kubernetes_version
  node_instance_type  = var.aws_node_instance_type
  node_min_size       = var.aws_node_min_size
  node_desired_size   = var.aws_node_desired_size
  node_max_size       = var.aws_node_max_size
  existing_eks_cluster_role_arn = var.aws_existing_eks_cluster_role_arn
  existing_eks_node_role_arn    = var.aws_existing_eks_node_role_arn

  db_instance_class    = var.aws_db_instance_class
  db_allocated_storage = var.aws_db_allocated_storage
  db_name              = var.aws_db_name
  db_username          = var.aws_db_username

  route53_domain_name  = var.aws_route53_domain_name
  enable_k8s_resources = var.aws_enable_k8s_resources
  k8s_namespace        = var.k8s_namespace
  app_secret_key       = var.app_secret_key
  tls_common_name      = var.tls_common_name
  tags                 = var.aws_tags
}
