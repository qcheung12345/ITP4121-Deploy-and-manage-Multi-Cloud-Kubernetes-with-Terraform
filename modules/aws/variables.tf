variable "project_name" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "existing_eks_cluster_role_arn" {
  type    = string
  default = ""
}

variable "existing_eks_node_role_arn" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = "app_db"
}

variable "db_username" {
  type    = string
  default = "app_user"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "k8s_namespace" {
  type    = string
  default = "guestbook"
}

variable "app_secret_key" {
  type      = string
  default   = "change-me-before-prod"
  sensitive = true
}

variable "app_image" {
  type    = string
  default = "guestbook-web:latest"
}

variable "app_replicas" {
  type    = number
  default = 2
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "tls_common_name" {
  type    = string
  default = "guestbook.example.com"
}

variable "route53_domain_name" {
  type    = string
  default = "guestbook.example.com"
}

variable "enable_k8s_resources" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention period in days"
  default     = 30
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., production, staging)"
  default     = "production"
}
