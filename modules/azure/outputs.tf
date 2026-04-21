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
  value = azurerm_log_analytics_workspace.guestbook.id
}

output "subnet_id_secondary" {
  value = azurerm_subnet.aks_secondary.id
}

output "database_hostname" {
  value = var.enable_managed_postgres ? azurerm_postgresql_flexible_server.postgres[0].fqdn : null
}

output "database_url" {
  value = var.enable_managed_postgres ? format(
    "postgresql://%s:%s@%s:5432/%s",
    var.postgres_user_name,
    random_password.postgres[0].result,
    azurerm_postgresql_flexible_server.postgres[0].fqdn,
    var.postgres_database_name,
  ) : null
}

output "database_user" {
  value = var.enable_managed_postgres ? var.postgres_user_name : null
}

output "database_password" {
  value     = var.enable_managed_postgres ? random_password.postgres[0].result : null
  sensitive = true
}
