variable "project_name" {
  type        = string
  description = "Base project name used in resource naming."
  default     = "itp4121-multicloud-k8s"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID. Can be omitted when already logged in with az CLI."
  default     = null
  nullable    = true
}

variable "azure_location" {
  type        = string
  description = "Azure region for AKS resources."
  default     = "eastasia"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Optional resource group name override."
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

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID used for GKE resources."
  default     = null
  nullable    = true
}

variable "gcp_region" {
  type        = string
  description = "GCP region for network and GKE cluster."
  default     = "asia-east2"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone for GKE node pool."
  default     = "asia-east2-a"
}

variable "gcp_network_cidr" {
  type        = string
  description = "CIDR block for GCP subnet."
  default     = "10.30.0.0/16"
}

variable "gcp_subnet_cidr" {
  type        = string
  description = "GCP subnet CIDR for GKE nodes."
  default     = "10.30.1.0/24"
}

variable "gcp_node_count" {
  type        = number
  description = "GKE node count."
  default     = 2
}

variable "gcp_machine_type" {
  type        = string
  description = "GKE node machine type."
  default     = "e2-standard-2"
}

variable "gcp_kubernetes_version" {
  type        = string
  description = "Optional GKE Kubernetes version."
  default     = null
  nullable    = true
}
