variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type     = string
  default  = null
  nullable = true
}

variable "vnet_cidr" {
  type = string
}

variable "aks_subnet_cidr" {
  type = string
}

variable "aks_subnet_cidr2" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_vm_size" {
  type = string
}

variable "kubernetes_version" {
  type     = string
  default  = null
  nullable = true
}

variable "aks_enable_node_public_ip" {
  type        = bool
  description = "Enable public IP on AKS nodes. Keep false for private subnets."
  default     = false
}

variable "enable_k8s_resources" {
  type        = bool
  description = "Enable Terraform-managed Kubernetes secrets and ingress resources."
  default     = false
}

variable "tls_common_name" {
  type        = string
  description = "Common name used by Azure ingress TLS certificate and host rule."
  default     = "guestbook.example.com"
}

variable "enable_managed_postgres" {
  type        = bool
  description = "Enable Azure managed PostgreSQL Flexible Server."
  default     = true
}

variable "postgres_version" {
  type        = string
  description = "Azure PostgreSQL major version."
  default     = "15"
}

variable "postgres_sku_name" {
  type        = string
  description = "Azure PostgreSQL Flexible Server SKU name."
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type        = number
  description = "Storage size in MB for Azure PostgreSQL Flexible Server."
  default     = 32768
}

variable "postgres_backup_retention_days" {
  type        = number
  description = "Backup retention days for Azure PostgreSQL Flexible Server."
  default     = 7
}

variable "postgres_database_name" {
  type        = string
  description = "Name of the Azure PostgreSQL database."
  default     = "app_db"
}

variable "postgres_user_name" {
  type        = string
  description = "Administrator username for Azure PostgreSQL Flexible Server."
  default     = "app_user"
}

variable "postgres_password_length" {
  type        = number
  description = "Generated password length for Azure PostgreSQL."
  default     = 16
}

variable "postgres_firewall_start_ip" {
  type        = string
  description = "Start IP for Azure PostgreSQL firewall rule."
  default     = "0.0.0.0"
}

variable "postgres_firewall_end_ip" {
  type        = string
  description = "End IP for Azure PostgreSQL firewall rule."
  default     = "255.255.255.255"
}
