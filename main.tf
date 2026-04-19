terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  project_name = var.project_name
  effective_app_database_url = (
    var.enable_gcp && var.gcp_enable_managed_postgres
    ? module.gcp[0].managed_database_url
    : var.app_database_url
  )
}

provider "azurerm" {
  features {}
  subscription_id                 = var.azure_subscription_id
  resource_provider_registrations = "none"
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "kubernetes" {
  config_path    = fileexists(pathexpand(var.kubeconfig_path)) ? pathexpand(var.kubeconfig_path) : null
  config_context = var.kubeconfig_context
}

module "azure" {
  count               = var.enable_azure ? 1 : 0
  source              = "./modules/azure"
  project_name        = local.project_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  vnet_cidr           = var.azure_vnet_cidr
  aks_subnet_cidr     = var.azure_aks_subnet_cidr
  aks_subnet_cidr2    = var.azure_aks_subnet_cidr2
  node_count          = var.azure_node_count
  node_vm_size        = var.azure_node_vm_size
  kubernetes_version  = var.azure_kubernetes_version
}

module "aws" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/aws"

  project_name         = local.project_name
  aws_region           = var.aws_region
  vpc_cidr             = var.aws_vpc_cidr
  public_subnet_cidrs  = var.aws_public_subnet_cidrs
  private_subnet_cidrs = var.aws_private_subnet_cidrs

  kubernetes_version  = var.aws_kubernetes_version
  node_instance_type  = var.aws_node_instance_type
  node_min_size       = var.aws_node_min_size
  node_desired_size   = var.aws_node_desired_size
  node_max_size       = var.aws_node_max_size

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

module "gcp" {
  count  = var.enable_gcp ? 1 : 0
  source = "./modules/gcp"
  providers = {
    kubernetes = kubernetes
  }
  project_name               = local.project_name
  project_id                 = var.gcp_project_id
  region                     = var.gcp_region
  zone                       = var.gcp_zone
  network_cidr               = var.gcp_network_cidr
  subnet_cidr                = var.gcp_subnet_cidr
  subnet_cidr2               = var.gcp_subnet_cidr2
  node_count                 = var.gcp_node_count
  machine_type               = var.gcp_machine_type
  kubernetes_version         = var.gcp_kubernetes_version
  enable_managed_postgres    = var.gcp_enable_managed_postgres
  postgres_version           = var.gcp_postgres_version
  postgres_tier              = var.gcp_postgres_tier
  postgres_database_name     = var.gcp_postgres_database_name
  postgres_user_name         = var.gcp_postgres_user_name
  postgres_authorized_cidr   = var.gcp_postgres_authorized_cidr
  enable_k8s_secrets         = var.enable_k8s_secrets
  kubeconfig_path            = var.kubeconfig_path
  kubeconfig_context         = var.kubeconfig_context
  k8s_namespace              = var.k8s_namespace
  effective_app_database_url = local.effective_app_database_url
  app_secret_key             = var.app_secret_key
  tls_common_name            = var.tls_common_name
}
