variable "project_name" {
  type    = string
  default = "itp4121-multicloud-k8s"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "aws_public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "aws_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "aws_kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "aws_node_instance_type" {
  type    = string
  default = "t3.small"
}

variable "aws_node_min_size" {
  type    = number
  default = 1
}

variable "aws_node_desired_size" {
  type    = number
  default = 1
}

variable "aws_node_max_size" {
  type    = number
  default = 3
}

variable "aws_existing_eks_cluster_role_arn" {
  type    = string
  default = ""
}

variable "aws_existing_eks_node_role_arn" {
  type    = string
  default = ""
}

variable "aws_db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "aws_db_allocated_storage" {
  type    = number
  default = 20
}

variable "aws_db_name" {
  type    = string
  default = "app_db"
}

variable "aws_db_username" {
  type    = string
  default = "app_user"
}

variable "aws_route53_domain_name" {
  type    = string
  default = "guestbook.example.com"
}

variable "aws_enable_k8s_resources" {
  type    = bool
  default = true
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

variable "tls_common_name" {
  type    = string
  default = "guestbook.example.com"
}

variable "aws_tags" {
  type = map(string)
  default = {
    project     = "itp4121"
    environment = "assignment"
    managed_by  = "terraform"
  }
}
