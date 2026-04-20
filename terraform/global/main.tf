/*
 * Global Multi-Cloud DNS Configuration for Route53
 * Provides weighted load balancing across AWS, Azure, and GCP regions
 * Part of 55-mark ITP4121 assignment: Global HA (5 marks)
 */

terraform {
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

# Use Route53 hosted zone
data "aws_route53_zone" "primary" {
  name = var.domain_name
  # Note: This assumes an existing hosted zone. Create if needed:
  # aws route53 create-hosted-zone --name example.com --caller-reference 1234567890
}

locals {
  azure_endpoint_is_ip = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.azure_lb_endpoint))

  weighted_endpoints = {
    aws = {
      weight          = 33
      endpoint        = var.aws_alb_endpoint
      record_type     = "CNAME"
      health_check_id = aws_route53_health_check.aws_guestbook.id
    }
    azure = {
      weight          = 33
      endpoint        = var.azure_lb_endpoint
      record_type     = local.azure_endpoint_is_ip ? "A" : "CNAME"
      health_check_id = aws_route53_health_check.azure_guestbook.id
    }
    gcp = {
      weight          = 34
      endpoint        = var.gcp_lb_endpoint
      record_type     = "CNAME"
      health_check_id = aws_route53_health_check.gcp_guestbook.id
    }
  }
}

resource "aws_route53_record" "guestbook_region" {
  for_each = local.weighted_endpoints

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "guestbook-${each.key}.${var.domain_name}"
  type    = each.value.record_type
  ttl     = var.route53_ttl
  records = [each.value.endpoint]
}

resource "aws_route53_record" "guestbook_weighted" {
  for_each = local.weighted_endpoints

  zone_id        = data.aws_route53_zone.primary.zone_id
  name           = "guestbook.${var.domain_name}"
  type           = "A"
  set_identifier = each.key

  weighted_routing_policy {
    weight = each.value.weight
  }

  health_check_id = each.value.health_check_id

  alias {
    name                   = aws_route53_record.guestbook_region[each.key].fqdn
    zone_id                = data.aws_route53_zone.primary.zone_id
    evaluate_target_health = true
  }
}

# Health check for AWS endpoint
resource "aws_route53_health_check" "aws_guestbook" {
  fqdn              = var.aws_alb_endpoint
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  measure_latency   = true

  tags = {
    Name = "guestbook-aws-health"
  }
}

# Health check for Azure endpoint
resource "aws_route53_health_check" "azure_guestbook" {
  fqdn              = local.azure_endpoint_is_ip ? null : var.azure_lb_endpoint
  ip_address        = local.azure_endpoint_is_ip ? var.azure_lb_endpoint : null
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  measure_latency   = true

  tags = {
    Name = "guestbook-azure-health"
  }
}

# Health check for GCP endpoint
resource "aws_route53_health_check" "gcp_guestbook" {
  fqdn              = var.gcp_lb_endpoint
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  measure_latency   = true

  tags = {
    Name = "guestbook-gcp-health"
  }
}

# CloudWatch alarms for Route53 health checks (monitoring)
resource "aws_cloudwatch_metric_alarm" "aws_guestbook_health" {
  alarm_name          = "guestbook-aws-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when AWS guestbook health check fails"
  dimensions = {
    HealthCheckId = aws_route53_health_check.aws_guestbook.id
  }
}

resource "aws_cloudwatch_metric_alarm" "azure_guestbook_health" {
  alarm_name          = "guestbook-azure-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when Azure guestbook health check fails"
  dimensions = {
    HealthCheckId = aws_route53_health_check.azure_guestbook.id
  }
}

resource "aws_cloudwatch_metric_alarm" "gcp_guestbook_health" {
  alarm_name          = "guestbook-gcp-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when GCP guestbook health check fails"
  dimensions = {
    HealthCheckId = aws_route53_health_check.gcp_guestbook.id
  }
}
