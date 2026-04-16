variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type     = string
  default  = null
  nullable = true
}

variable "vnet_cidr" {
  type = string
}

variable "aks_subnet_cidr" {
  type = string
}

variable "aks_subnet_cidr2" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_vm_size" {
  type = string
}

variable "kubernetes_version" {
  type     = string
  default  = null
  nullable = true
}

locals {
  rg_name      = coalesce(var.resource_group_name, "${var.project_name}-azure-rg")
  vnet_name    = "${var.project_name}-azure-vnet"
  subnet_name  = "${var.project_name}-azure-aks-subnet"
  subnet_name2 = "${var.project_name}-azure-aks-subnet-2"
  aks_name     = substr(replace("${var.project_name}-azure-aks", "_", "-"), 0, 63)
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "aks_secondary" {
  name                 = local.subnet_name2
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr2]
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = local.aks_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = substr(replace("${var.project_name}-dns", "_", "-"), 0, 54)

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name               = "system"
    node_count         = var.node_count
    vm_size            = var.node_vm_size
    vnet_subnet_id     = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count          = 1
    max_count          = 5
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
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

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "subnet_id" {
  value = azurerm_subnet.aks.id
}

output "subnet_id_secondary" {
  value = azurerm_subnet.aks_secondary.id
}
