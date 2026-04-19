output "gcp_gke_cluster_name" {
  value = module.gcp.cluster_name
}

output "gcp_project_id" {
  value = var.gcp_project_id
}

output "gcp_region" {
  value = var.gcp_region
}

output "gcp_network_name" {
  value = module.gcp.network_name
}

output "gcp_managed_database_url" {
  value     = module.gcp.managed_database_url
  sensitive = true
}
