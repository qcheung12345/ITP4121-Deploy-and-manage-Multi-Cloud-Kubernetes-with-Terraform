output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "eks_cluster_ca_data" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "eks_node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "database_url" {
  value     = local.database_url
  sensitive = true
}

output "elb_hostname" {
  value = var.enable_k8s_resources ? try(kubernetes_service.guestbook_web[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
}

output "route53_zone_id" {
  value = aws_route53_zone.this.zone_id
}

output "route53_name_servers" {
  value = aws_route53_zone.this.name_servers
}
