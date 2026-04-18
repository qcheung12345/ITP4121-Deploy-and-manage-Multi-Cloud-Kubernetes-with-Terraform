resource "random_password" "postgres" {
  count   = var.enable_managed_postgres ? 1 : 0
  length  = 20
  special = false
}

resource "google_sql_database_instance" "postgres" {
  count            = var.enable_managed_postgres ? 1 : 0
  name             = local.postgres_instance_name
  database_version = var.postgres_version
  region           = var.region

  settings {
    tier = var.postgres_tier

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "assignment-access"
        value = var.postgres_authorized_cidr
      }
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false

  depends_on = [
    google_project_service.sqladmin,
  ]
}

resource "google_sql_database" "app" {
  count    = var.enable_managed_postgres ? 1 : 0
  name     = var.postgres_database_name
  instance = google_sql_database_instance.postgres[0].name
}

resource "google_sql_user" "app" {
  count    = var.enable_managed_postgres ? 1 : 0
  instance = google_sql_database_instance.postgres[0].name
  name     = var.postgres_user_name
  password = random_password.postgres[0].result
}
