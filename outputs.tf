output "azure_resource_group_name" {
  value = var.enable_azure ? module.azure[0].resource_group_name : null
}

output "azure_aks_cluster_name" {
  value = var.enable_azure ? module.azure[0].cluster_name : null
}

output "azure_log_analytics_workspace_id" {
  value = var.enable_azure ? module.azure[0].log_analytics_workspace_id : null
}

output "gcp_gke_cluster_name" {
  value = var.enable_gcp ? module.gcp[0].cluster_name : null
}

output "gcp_network_name" {
  value = var.enable_gcp ? module.gcp[0].network_name : null
}

output "gcp_managed_database_public_ip" {
  value = var.enable_gcp ? module.gcp[0].managed_database_public_ip : null
}

output "gcp_managed_database_url" {
  value     = var.enable_gcp ? module.gcp[0].managed_database_url : null
  sensitive = true
}

output "gcp_project_id" {
  value = var.enable_gcp ? var.gcp_project_id : null
}

output "gcp_region" {
  value = var.enable_gcp ? var.gcp_region : null
}
