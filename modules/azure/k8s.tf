resource "azurerm_kubernetes_cluster" "this" {
  name                = local.aks_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = substr(replace("${var.project_name}-dns", "_", "-"), 0, 54)

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  role_based_access_control_enabled = true
}

resource "azurerm_kubernetes_cluster_node_pool" "secondary" {
  name                  = "secondary"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.node_vm_size
  node_count            = 1
  vnet_subnet_id        = azurerm_subnet.aks_secondary.id

  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 3
}