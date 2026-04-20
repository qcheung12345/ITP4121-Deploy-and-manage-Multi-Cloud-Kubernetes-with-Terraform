# Azure Log Analytics for Logging and Monitoring
# Part of 55-mark ITP4121 assignment: Cloud Logging (5 marks)

resource "azurerm_log_analytics_workspace" "guestbook" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "production"
    Application = "guestbook"
  }
}

# Enable AKS cluster diagnostics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name               = "${local.aks_name}-diagnostics"
  target_resource_id = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.guestbook.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Application Insights for detailed application monitoring
resource "azurerm_application_insights" "guestbook" {
  name                = "${local.aks_name}-appinsights"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.guestbook.id
  application_type    = "web"

  tags = {
    Environment = "production"
    Application = "guestbook"
  }
}

# Azure Monitor metric alerts are disabled because these metrics are not available
# in this AKS metric namespace and currently cause API 400 errors during apply.
resource "azurerm_monitor_metric_alert" "aks_node_availability" {
  count               = 0
  name                = "${local.aks_name}-node-availability"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  frequency           = "PT1M"
  window_size         = "PT5M"
  severity            = 2

  criteria {
    metric_name      = "node_cpu_percent"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = "90"
  }

  tags = {
    Environment = "production"
  }
}

resource "azurerm_monitor_metric_alert" "failed_pod_deployments" {
  count               = 0
  name                = "${local.aks_name}-failed-deployments"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  frequency           = "PT1M"
  window_size         = "PT5M"
  severity            = 3

  criteria {
    metric_name      = "pod_status"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = "1"
  }

  tags = {
    Environment = "production"
  }
}

# Log Analytics query saved for database connectivity monitoring
resource "azurerm_log_analytics_saved_search" "database_connectivity" {
  name                       = "DatabaseConnectivityMonitoring"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.guestbook.id
  category                   = "Guestbook Database"
  display_name               = "Database Connectivity Issues"
  query                      = "ContainerLog | where LogEntry contains 'database' or LogEntry contains 'connection' | summarize count() by Computer"
}

# Kubernetes Event Grid Topic integration for event logging (optional advanced feature)
resource "azurerm_log_analytics_saved_search" "pod_events" {
  name                       = "PodEventTracking"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.guestbook.id
  category                   = "Kubernetes Events"
  display_name               = "Pod Lifecycle Events"
  query                      = "KubePodInventory | where PodStatus contains 'Pending' or PodStatus contains 'Failed' | summarize count() by Namespace"
}
