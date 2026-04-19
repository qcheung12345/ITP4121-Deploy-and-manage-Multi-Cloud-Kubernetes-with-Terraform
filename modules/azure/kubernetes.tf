resource "azurerm_log_analytics_workspace" "this" {
  count               = 0 # Disabled due to subscription region restrictions
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}