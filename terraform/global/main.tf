terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_health_check" "azure_guestbook" {
  ip_address        = var.azure_lb_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_health_check" "gcp_guestbook" {
  ip_address        = var.gcp_lb_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "guestbook_weighted_azure" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "guestbook.${var.domain_name}"
  type    = "A"
  ttl     = var.route53_ttl
  records = [var.azure_lb_ip]

  set_identifier  = "azure"
  health_check_id = aws_route53_health_check.azure_guestbook.id

  weighted_routing_policy {
    weight = var.azure_weight
  }
}

resource "aws_route53_record" "guestbook_weighted_gcp" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "guestbook.${var.domain_name}"
  type    = "A"
  ttl     = var.route53_ttl
  records = [var.gcp_lb_ip]

  set_identifier  = "gcp"
  health_check_id = aws_route53_health_check.gcp_guestbook.id

  weighted_routing_policy {
    weight = var.gcp_weight
  }
}
