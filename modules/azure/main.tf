locals {
  rg_name            = coalesce(var.resource_group_name, "${var.project_name}-azure-rg")
  vnet_name          = "${var.project_name}-azure-vnet"
  subnet_name        = "${var.project_name}-azure-aks-subnet"
  subnet_name2       = "${var.project_name}-azure-aks-subnet-2"
  aks_name           = substr(replace("${var.project_name}-azure-aks", "_", "-"), 0, 63)
  log_analytics_name = substr(replace("${var.project_name}-la", "_", "-"), 0, 63)
}
