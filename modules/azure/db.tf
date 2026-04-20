locals {
  postgres_server_name = substr(replace("${var.project_name}-pg", "_", "-"), 0, 63)
}

resource "random_password" "postgres" {
  count            = var.enable_managed_postgres ? 1 : 0
  length           = var.postgres_password_length
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>?"
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  count                         = var.enable_managed_postgres ? 1 : 0
  name                          = local.postgres_server_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  administrator_login           = var.postgres_user_name
  administrator_password        = random_password.postgres[0].result
  version                       = var.postgres_version
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  backup_retention_days         = var.postgres_backup_retention_days
  public_network_access_enabled = true

  lifecycle {
    ignore_changes = [
      zone,
      high_availability,
    ]
  }

  tags = {
    project = var.project_name
    env     = "azure"
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  count     = var.enable_managed_postgres ? 1 : 0
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  charset   = "UTF8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  count            = var.enable_managed_postgres ? 1 : 0
  name             = "allow-all"
  server_id        = azurerm_postgresql_flexible_server.postgres[0].id
  start_ip_address = var.postgres_firewall_start_ip
  end_ip_address   = var.postgres_firewall_end_ip
}
