resource "google_container_cluster" "this" {
  name     = local.cluster_name
  location = var.region

  network    = google_compute_network.this.name
  subnetwork = google_compute_subnetwork.this.name

  remove_default_node_pool = true
  initial_node_count       = var.node_count

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
      maximum       = 3
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 4
    }
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.container,
  ]
}

resource "google_container_node_pool" "primary" {
  name     = "primary-node-pool"
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = 1
    max_node_count = 3
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
