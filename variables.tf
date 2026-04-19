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

variable "enable_azure" {
  type        = bool
  description = "Set to true to deploy the Azure stack."
  default     = false
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

variable "azure_aks_subnet_cidr2" {
  type        = string
  description = "CIDR block for a second AKS private subnet."
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

variable "enable_aws" {
  type        = bool
  description = "Set to true to deploy the AWS stack."
  default     = false
}

variable "aws_region" {
  type        = string
  description = "AWS region for VPC, EKS, and RDS resources."
  default     = "ap-east-1"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "CIDR block for AWS VPC."
  default     = "10.1.0.0/16"
}

variable "aws_public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for AWS public subnets."
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "aws_private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for AWS private subnets."
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "aws_kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = "1.30"
}

variable "aws_node_instance_type" {
  type        = string
  description = "EKS node instance type."
  default     = "t3.small"
}

variable "aws_node_min_size" {
  type        = number
  description = "EKS node group minimum size."
  default     = 1
}

variable "aws_node_desired_size" {
  type        = number
  description = "EKS node group desired size."
  default     = 1
}

variable "aws_node_max_size" {
  type        = number
  description = "EKS node group maximum size."
  default     = 3
}

variable "aws_db_instance_class" {
  type        = string
  description = "RDS PostgreSQL instance class."
  default     = "db.t3.micro"
}

variable "aws_db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB for RDS PostgreSQL."
  default     = 20
}

variable "aws_db_name" {
  type        = string
  description = "Database name for AWS RDS PostgreSQL."
  default     = "app_db"
}

variable "aws_db_username" {
  type        = string
  description = "Database username for AWS RDS PostgreSQL."
  default     = "app_user"
}

variable "aws_route53_domain_name" {
  type        = string
  description = "Route53 public hosted zone domain name."
  default     = "guestbook.example.com"
}

variable "aws_enable_k8s_resources" {
  type        = bool
  description = "Set to true to create Kubernetes resources from AWS module."
  default     = false
}

variable "aws_tags" {
  type        = map(string)
  description = "Common tags applied to AWS resources."
  default     = {}
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID used for GKE resources."
  default     = null
  nullable    = true
}

variable "gcp_access_token" {
  type        = string
  description = "Optional GCP access token. Override it only when enable_gcp is true."
  default     = "disabled"
}

variable "enable_gcp" {
  type        = bool
  description = "Set to true to deploy the GCP stack."
  default     = false
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

variable "gcp_subnet_cidr2" {
  type        = string
  description = "Secondary GCP subnet CIDR for private resources."
  default     = "10.30.2.0/24"
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

variable "gcp_enable_managed_postgres" {
  type        = bool
  description = "Set to true to create Cloud SQL for PostgreSQL in GCP module."
  default     = false
}

variable "gcp_postgres_version" {
  type        = string
  description = "Cloud SQL PostgreSQL major version."
  default     = "POSTGRES_15"
}

variable "gcp_postgres_tier" {
  type        = string
  description = "Cloud SQL instance machine tier."
  default     = "db-custom-1-3840"
}

variable "gcp_postgres_database_name" {
  type        = string
  description = "Cloud SQL database name used by guestbook app."
  default     = "app_db"
}

variable "gcp_postgres_user_name" {
  type        = string
  description = "Cloud SQL database username for guestbook app."
  default     = "app_user"
}

variable "gcp_postgres_authorized_cidr" {
  type        = string
  description = "CIDR allowed to access Cloud SQL public endpoint."
  default     = "0.0.0.0/0"
}

variable "enable_k8s_secrets" {
  type        = bool
  description = "Set to true to create Kubernetes app and TLS secrets via Terraform."
  default     = false
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig used by Terraform Kubernetes provider."
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  type        = string
  description = "Optional kubeconfig context used by Terraform Kubernetes provider."
  default     = null
  nullable    = true
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace where guestbook app resources are deployed."
  default     = "guestbook"
}

variable "app_database_url" {
  type        = string
  description = "Database URL injected into app secret as DATABASE_URL."
  default     = "postgresql://app_user:change-me@postgres.guestbook.svc.cluster.local:5432/app_db"
  sensitive   = true
}

variable "app_secret_key" {
  type        = string
  description = "Application secret key injected into app secret as SECRET_KEY."
  default     = "change-me-before-prod"
  sensitive   = true
}

variable "tls_common_name" {
  type        = string
  description = "Common name for self-signed TLS certificate."
  default     = "guestbook.example.com"
}
