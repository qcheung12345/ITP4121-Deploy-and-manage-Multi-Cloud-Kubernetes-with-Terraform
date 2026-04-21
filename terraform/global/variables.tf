variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID. Can be omitted when az CLI context is set."
  default     = null
  nullable    = true
}

variable "azure_location" {
  type        = string
  description = "Azure region for global DNS resources."
  default     = "eastus"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Resource group name hosting the Azure Traffic Manager profile."
  default     = "itp4121-global-dns-rg"
}

variable "traffic_manager_profile_name" {
  type        = string
  description = "Traffic Manager profile resource name."
  default     = "itp4121-guestbook-tm"
}

variable "traffic_manager_dns_relative_name" {
  type        = string
  description = "DNS relative name under trafficmanager.net."
  default     = "itp4121-guestbook"
}

variable "traffic_manager_dns_ttl" {
  type        = number
  description = "TTL for the Traffic Manager DNS profile."
  default     = 60
}

variable "azure_lb_ip" {
  type        = string
  description = "Azure guestbook public endpoint (IP or hostname)."
}

variable "gcp_lb_ip" {
  type        = string
  description = "GCP guestbook public endpoint (IP or hostname)."
}

variable "azure_endpoint_location" {
  type        = string
  description = "Endpoint location metadata for Azure endpoint in Traffic Manager."
  default     = "eastus"
}

variable "gcp_endpoint_location" {
  type        = string
  description = "Endpoint location metadata for GCP endpoint in Traffic Manager."
  default     = "westus"
}

variable "azure_weight" {
  type        = number
  description = "Weighted routing value for Azure endpoint (1-1000)."
  default     = 50
}

variable "gcp_weight" {
  type        = number
  description = "Weighted routing value for GCP endpoint (1-1000)."
  default     = 50
}
