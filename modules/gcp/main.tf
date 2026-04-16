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

locals {
  network_name = "${var.project_name}-gcp-vpc"
  subnet_name  = "${var.project_name}-gcp-subnet"
  cluster_name = substr(replace("${var.project_name}-gke", "_", "-"), 0, 40)
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

  ip_allocation_policy {}

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 10
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 20
    }
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.this.name
  node_count = var.node_count

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

output "cluster_name" {
  value = google_container_cluster.this.name
}

output "network_name" {
  value = google_compute_network.this.name
}

output "subnet_name_secondary" {
  value = google_compute_subnetwork.secondary.name
}
