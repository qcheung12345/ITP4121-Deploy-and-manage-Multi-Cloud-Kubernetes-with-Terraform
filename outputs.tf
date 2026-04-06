output "azure_resource_group_name" {
  value = module.azure.resource_group_name
}

output "azure_aks_cluster_name" {
  value = module.azure.cluster_name
}

output "gcp_gke_cluster_name" {
  value = module.gcp.cluster_name
}

output "gcp_network_name" {
  value = module.gcp.network_name
}
