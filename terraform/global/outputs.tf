output "guestbook_global_fqdn" {
  description = "Azure Traffic Manager global DNS name."
  value       = azurerm_traffic_manager_profile.guestbook.fqdn
}

output "weighted_routing_policy" {
  value = {
    azure_weight = var.azure_weight
    gcp_weight   = var.gcp_weight
  }
}

output "traffic_manager_profile_id" {
  value = azurerm_traffic_manager_profile.guestbook.id
}

output "azure_endpoint_target" {
  value = azurerm_traffic_manager_external_endpoint.azure_guestbook.target
}

output "gcp_endpoint_target" {
  value = azurerm_traffic_manager_external_endpoint.gcp_guestbook.target
}

output "demo_dig_command" {
  value = "dig +short ${azurerm_traffic_manager_profile.guestbook.fqdn}"
}
