terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  network_name           = "${var.project_name}-gcp-vpc"
  subnet_name            = "${var.project_name}-gcp-subnet"
  cluster_name           = substr(replace("${var.project_name}-gke", "_", "-"), 0, 40)
  postgres_instance_name = substr(replace("${var.project_name}-pg", "_", "-"), 0, 62)
}
