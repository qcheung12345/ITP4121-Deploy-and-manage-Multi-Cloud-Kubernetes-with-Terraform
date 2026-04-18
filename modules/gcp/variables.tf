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

variable "enable_k8s_secrets" {
  type = bool
}

variable "kubeconfig_path" {
  type = string
}

variable "kubeconfig_context" {
  type     = string
  default  = null
  nullable = true
}

variable "k8s_namespace" {
  type = string
}

variable "effective_app_database_url" {
  type = string
}

variable "app_secret_key" {
  type = string
}

variable "tls_common_name" {
  type = string
}
