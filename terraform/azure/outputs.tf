output "azure_resource_group_name" {
  value = local.resolved_resource_group_name
}

output "azure_aks_cluster_name" {
  value = local.resolved_cluster_name
}

output "azure_subnet_id" {
  value = module.azure.subnet_id
}

output "azure_subnet_id_secondary" {
  value = module.azure.subnet_id_secondary
}

output "flask_app_status" {
  value = local.flask_app_status
}

output "flask_app_ip" {
  value = local.flask_app_ip != "" ? local.flask_app_ip : null
}

output "flask_app_hostname" {
  value = local.flask_app_hostname != "" ? local.flask_app_hostname : null
}

output "flask_app_url" {
  value = local.flask_app_url
}

output "azure_database_url" {
  value     = module.azure.database_url
  sensitive = true
}

output "azure_database_user" {
  value = module.azure.database_user
}

output "azure_database_password" {
  value     = module.azure.database_password
  sensitive = true
}
