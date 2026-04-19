variable "project_name" {
  type    = string
  default = "itp4121-multicloud-k8s"
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_access_token" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_network_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "gcp_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}

variable "gcp_subnet_cidr2" {
  type    = string
  default = "10.30.2.0/24"
}

variable "gcp_node_count" {
  type    = number
  default = 1
}

variable "gcp_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "gcp_kubernetes_version" {
  type     = string
  default  = null
  nullable = true
}

variable "gcp_enable_managed_postgres" {
  type    = bool
  default = false
}

variable "gcp_postgres_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "gcp_postgres_tier" {
  type    = string
  default = "db-custom-1-3840"
}

variable "gcp_postgres_database_name" {
  type    = string
  default = "app_db"
}

variable "gcp_postgres_user_name" {
  type    = string
  default = "app_user"
}

variable "gcp_postgres_authorized_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "enable_k8s_secrets" {
  type    = bool
  default = false
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubeconfig_context" {
  type     = string
  default  = null
  nullable = true
}

variable "k8s_namespace" {
  type    = string
  default = "guestbook"
}

variable "app_database_url" {
  type      = string
  default   = "postgresql://app_user:change-me@postgres.guestbook.svc.cluster.local:5432/app_db"
  sensitive = true
}

variable "app_secret_key" {
  type      = string
  default   = "change-me-before-prod"
  sensitive = true
}

variable "tls_common_name" {
  type    = string
  default = "guestbook.example.com"
}
