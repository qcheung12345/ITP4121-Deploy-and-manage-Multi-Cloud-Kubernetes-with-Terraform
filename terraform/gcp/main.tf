terraform {
  required_version = ">= 1.8.0"

  required_providers {
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

provider "google" {
  project      = var.gcp_project_id
  region       = var.gcp_region
  access_token = var.gcp_access_token
}

provider "kubernetes" {
  config_path    = fileexists(pathexpand(var.kubeconfig_path)) ? pathexpand(var.kubeconfig_path) : null
  config_context = var.kubeconfig_context
}

locals {
  effective_app_database_url = (
    var.gcp_enable_managed_postgres
    ? module.gcp.managed_database_url
    : var.app_database_url
  )
}

module "gcp" {
  source = "../../modules/gcp"

  providers = {
    kubernetes = kubernetes
  }

  project_name               = var.project_name
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
  gke_region                 = var.gcp_region
  gke_cluster_name           = substr(replace("${var.project_name}-gke", "_", "-"), 0, 40)
}
