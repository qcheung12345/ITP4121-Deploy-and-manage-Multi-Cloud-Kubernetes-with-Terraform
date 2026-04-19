variable "project_name" {
  type        = string
  description = "Base project name used in Azure resource naming."
  default     = "itp4121-multicloud-k8s"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID. Can be omitted when az CLI context is set."
  default     = null
  nullable    = true
}

variable "azure_location" {
  type        = string
  description = "Azure region for AKS resources."
  default     = "westus"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Optional Azure resource group override."
  default     = null
  nullable    = true
}

variable "azure_vnet_cidr" {
  type        = string
  description = "CIDR block for Azure virtual network."
  default     = "10.20.0.0/16"
}

variable "azure_aks_subnet_cidr" {
  type        = string
  description = "CIDR block for AKS node subnet."
  default     = "10.20.1.0/24"
}

variable "azure_aks_subnet_cidr2" {
  type        = string
  description = "CIDR block for second AKS node subnet."
  default     = "10.20.2.0/24"
}

variable "azure_node_count" {
  type        = number
  description = "AKS default node count."
  default     = 2
}

variable "azure_node_vm_size" {
  type        = string
  description = "AKS node VM size."
  default     = "Standard_DS2_v2"
}

variable "azure_kubernetes_version" {
  type        = string
  description = "Optional AKS Kubernetes version."
  default     = null
  nullable    = true
}

variable "root_state_path" {
  type        = string
  description = "Deprecated. Kept for compatibility and not used by this stack."
  default     = "../../terraform.tfstate"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace where the website service exists."
  default     = "guestbook"
}

variable "web_service_name" {
  type        = string
  description = "Kubernetes service name for the website frontend."
  default     = "guestbook-web"
}
