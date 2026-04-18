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
