output "guestbook_global_fqdn" {
  description = "Weighted global guestbook record."
  value       = "guestbook.${var.domain_name}"
}

output "weighted_routing_policy" {
  value = {
    azure_weight = var.azure_weight
    gcp_weight   = var.gcp_weight
  }
}

output "azure_health_check_id" {
  value = aws_route53_health_check.azure_guestbook.id
}

output "gcp_health_check_id" {
  value = aws_route53_health_check.gcp_guestbook.id
}

output "demo_dig_command" {
  value = "dig +short guestbook.${var.domain_name}"
}
