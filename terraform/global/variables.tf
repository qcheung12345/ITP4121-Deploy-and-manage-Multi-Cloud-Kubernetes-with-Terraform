variable "aws_region" {
  type        = string
  description = "AWS region for Route53 resources."
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "Existing public hosted zone name, for example example.com"
  default     = "example.com"
}

variable "route53_ttl" {
  type        = number
  description = "TTL for guestbook weighted DNS records."
  default     = 60
}

variable "azure_lb_ip" {
  type        = string
  description = "Azure guestbook public load balancer IP."
}

variable "gcp_lb_ip" {
  type        = string
  description = "GCP guestbook public load balancer IP."
}

variable "azure_weight" {
  type        = number
  description = "Weighted routing value for Azure endpoint."
  default     = 50
}

variable "gcp_weight" {
  type        = number
  description = "Weighted routing value for GCP endpoint."
  default     = 50
}
