output "guestbook_global_fqdn" {
  description = "Global FQDN for guestbook with weighted multi-cloud routing"
  value       = "guestbook.${var.domain_name}"
}

output "guestbook_aws_endpoint" {
  description = "AWS regional guestbook endpoint"
  value       = "guestbook-aws.${var.domain_name}"
}

output "guestbook_azure_endpoint" {
  description = "Azure regional guestbook endpoint"
  value       = "guestbook-azure.${var.domain_name}"
}

output "guestbook_gcp_endpoint" {
  description = "GCP regional guestbook endpoint"
  value       = "guestbook-gcp.${var.domain_name}"
}

output "route53_health_checks" {
  description = "Health check IDs for multi-cloud endpoints"
  value = {
    aws_health_check_id   = try(aws_route53_health_check.aws_guestbook.id, "")
    azure_health_check_id = try(aws_route53_health_check.azure_guestbook.id, "")
    gcp_health_check_id   = try(aws_route53_health_check.gcp_guestbook.id, "")
  }
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm ARNs for health check monitoring"
  value = {
    aws_alarm_arn   = try(aws_cloudwatch_metric_alarm.aws_guestbook_health.arn, "")
    azure_alarm_arn = try(aws_cloudwatch_metric_alarm.azure_guestbook_health.arn, "")
    gcp_alarm_arn   = try(aws_cloudwatch_metric_alarm.gcp_guestbook_health.arn, "")
  }
}

output "weighted_routing_policy" {
  description = "Weighted routing distribution across clouds"
  value = {
    aws_weight   = 33
    azure_weight = 33
    gcp_weight   = 34
  }
}
