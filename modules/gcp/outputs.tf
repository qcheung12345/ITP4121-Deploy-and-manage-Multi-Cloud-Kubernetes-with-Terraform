output "cluster_name" {
  value = google_container_cluster.this.name
}

output "network_name" {
  value = google_compute_network.this.name
}

output "managed_database_url" {
  value = var.enable_managed_postgres ? format(
    "postgresql://%s:%s@%s:5432/%s",
    google_sql_user.app[0].name,
    random_password.postgres[0].result,
    google_sql_database_instance.postgres[0].public_ip_address,
    google_sql_database.app[0].name,
  ) : null
  sensitive = true
}

output "managed_database_public_ip" {
  value = var.enable_managed_postgres ? google_sql_database_instance.postgres[0].public_ip_address : null
}

output "subnet_name_secondary" {
  value = google_compute_subnetwork.secondary.name
}
