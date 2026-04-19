terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.azure_subscription_id
  resource_provider_registrations = "none"
}

module "azure" {
  source = "../../modules/azure"

  project_name        = var.project_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  vnet_cidr           = var.azure_vnet_cidr
  aks_subnet_cidr     = var.azure_aks_subnet_cidr
  aks_subnet_cidr2    = var.azure_aks_subnet_cidr2
  node_count          = var.azure_node_count
  node_vm_size        = var.azure_node_vm_size
  kubernetes_version  = var.azure_kubernetes_version
}

data "external" "guestbook_web_lb" {
  program = [
    "bash",
    "-lc",
    <<-EOT
      set -euo pipefail

      NS="${var.k8s_namespace}"
      SVC="${var.web_service_name}"

      if ! command -v kubectl >/dev/null 2>&1; then
        printf '{"status":"kubectl_missing","ip":"","hostname":""}\n'
        exit 0
      fi

      if ! kubectl get svc "$SVC" -n "$NS" >/dev/null 2>&1; then
        printf '{"status":"service_missing","ip":"","hostname":""}\n'
        exit 0
      fi

      IP="$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
      HOSTNAME="$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

      STATUS="ready"
      if [ -z "$IP" ] && [ -z "$HOSTNAME" ]; then
        STATUS="pending"
      fi

      printf '{"status":"%s","ip":"%s","hostname":"%s"}\n' "$STATUS" "$IP" "$HOSTNAME"
    EOT
  ]
}

locals {
  resolved_resource_group_name = module.azure.resource_group_name
  resolved_cluster_name        = module.azure.cluster_name

  flask_app_ip       = try(data.external.guestbook_web_lb.result.ip, "")
  flask_app_hostname = try(data.external.guestbook_web_lb.result.hostname, "")
  flask_app_status   = try(data.external.guestbook_web_lb.result.status, "unknown")

  flask_app_endpoint = (
    local.flask_app_ip != ""
    ? local.flask_app_ip
    : (local.flask_app_hostname != "" ? local.flask_app_hostname : "pending")
  )

  flask_app_url = local.flask_app_endpoint == "pending" ? "pending" : "http://${local.flask_app_endpoint}"
}
