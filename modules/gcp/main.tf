variable "project_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_cidr2" {
  type = string
}

variable "node_count" {
  type = number
}

variable "machine_type" {
  type = string
}

variable "kubernetes_version" {
  type     = string
  default  = null
  nullable = true
}

variable "enable_managed_postgres" {
  type = bool
}

variable "postgres_version" {
  type = string
}

variable "postgres_tier" {
  type = string
}

variable "postgres_database_name" {
  type = string
}

variable "postgres_user_name" {
  type = string
}

variable "postgres_authorized_cidr" {
  type = string
}

locals {
  network_name           = "${var.project_name}-gcp-vpc"
  subnet_name            = "${var.project_name}-gcp-subnet"
  cluster_name           = substr(replace("${var.project_name}-gke", "_", "-"), 0, 40)
  postgres_instance_name = substr(replace("${var.project_name}-pg", "_", "-"), 0, 62)
}

resource "google_compute_network" "this" {
  name                    = local.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = local.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_subnetwork" "secondary" {
  name          = "${local.network_name}-secondary"
  ip_cidr_range = var.subnet_cidr2
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_container_cluster" "this" {
  name     = local.cluster_name
  location = var.region

  network    = google_compute_network.this.name
  subnetwork = google_compute_subnetwork.this.name

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version  = var.kubernetes_version
  deletion_protection = false
  logging_service     = "logging.googleapis.com/kubernetes"
  monitoring_service  = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {}

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 2
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 4
    }
  }
}

resource "google_container_node_pool" "primary" {
  name     = "primary-node-pool"
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      environment = "assignment"
    }
  }
}

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
