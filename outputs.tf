output "azure_resource_group_name" {
  value = var.enable_azure ? module.azure[0].resource_group_name : null
}

output "azure_aks_cluster_name" {
  value = var.enable_azure ? module.azure[0].cluster_name : null
}

output "gcp_gke_cluster_name" {
  value = var.enable_gcp ? module.gcp[0].cluster_name : null
}

output "gcp_network_name" {
  value = var.enable_gcp ? module.gcp[0].network_name : null
}
