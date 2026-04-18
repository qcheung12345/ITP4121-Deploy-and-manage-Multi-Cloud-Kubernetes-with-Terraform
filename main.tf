terraform {
  required_version = ">= 1.8.0"

  required_providers {
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

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
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

module "gcp" {
  count                    = var.enable_gcp ? 1 : 0
  source                   = "./modules/gcp"
  project_name             = local.project_name
  project_id               = var.gcp_project_id
  region                   = var.gcp_region
  zone                     = var.gcp_zone
  network_cidr             = var.gcp_network_cidr
  subnet_cidr              = var.gcp_subnet_cidr
  subnet_cidr2             = var.gcp_subnet_cidr2
  node_count               = var.gcp_node_count
  machine_type             = var.gcp_machine_type
  kubernetes_version       = var.gcp_kubernetes_version
  enable_managed_postgres  = var.gcp_enable_managed_postgres
  postgres_version         = var.gcp_postgres_version
  postgres_tier            = var.gcp_postgres_tier
  postgres_database_name   = var.gcp_postgres_database_name
  postgres_user_name       = var.gcp_postgres_user_name
  postgres_authorized_cidr = var.gcp_postgres_authorized_cidr
}
