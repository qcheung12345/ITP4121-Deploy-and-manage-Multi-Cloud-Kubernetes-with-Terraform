variable "aws_region" {
  type        = string
  description = "AWS region for Route53"
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "Domain name for multi-cloud DNS (e.g., example.com)"
  default     = "example.com"
}

variable "route53_ttl" {
  type        = number
  description = "TTL for Route53 DNS records in seconds"
  default     = 300
}

# Load balancer endpoints from each cloud
variable "aws_alb_endpoint" {
  type        = string
  description = "AWS ALB endpoint for guestbook application"
  default     = "guestbook-alb.elb.us-east-1.amazonaws.com"
}

variable "azure_lb_endpoint" {
  type        = string
  description = "Azure LoadBalancer endpoint for guestbook application"
  default     = "4.253.8.202"
}

variable "gcp_lb_endpoint" {
  type        = string
  description = "GCP Load Balancer endpoint for guestbook application"
  default     = "guestbook-lb.c.PROJECT_ID.internal"
}

variable "enable_health_checks" {
  type        = bool
  description = "Enable Route53 health checks for all endpoints"
  default     = true
}

variable "enable_cloudwatch_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms for health check failures"
  default     = true
}
