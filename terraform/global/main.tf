terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.azure_subscription_id
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "traffic_manager" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

locals {
  azure_target = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.azure_lb_ip)) ? "azure.${replace(var.azure_lb_ip, ".", "-")}.nip.io" : var.azure_lb_ip
  gcp_target   = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.gcp_lb_ip)) ? "gcp.${replace(var.gcp_lb_ip, ".", "-")}.nip.io" : var.gcp_lb_ip
}

resource "azurerm_traffic_manager_profile" "guestbook" {
  name                = var.traffic_manager_profile_name
  resource_group_name = azurerm_resource_group.traffic_manager.name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = var.traffic_manager_dns_relative_name
    ttl           = var.traffic_manager_dns_ttl
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_external_endpoint" "azure_guestbook" {
  name               = "azure"
  profile_id         = azurerm_traffic_manager_profile.guestbook.id
  target             = local.azure_target
  endpoint_location  = var.azure_endpoint_location
  weight             = var.azure_weight
  always_serve_enabled = true
}

resource "azurerm_traffic_manager_external_endpoint" "gcp_guestbook" {
  name               = "gcp"
  profile_id         = azurerm_traffic_manager_profile.guestbook.id
  target             = local.gcp_target
  endpoint_location  = var.gcp_endpoint_location
  weight             = var.gcp_weight
  always_serve_enabled = true
}
