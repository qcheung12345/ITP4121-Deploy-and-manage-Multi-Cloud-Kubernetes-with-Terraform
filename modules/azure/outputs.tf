output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "subnet_id" {
  value = azurerm_subnet.aks.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "subnet_id_secondary" {
  value = azurerm_subnet.aks_secondary.id
}
