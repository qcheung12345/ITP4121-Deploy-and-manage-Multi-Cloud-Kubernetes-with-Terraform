output "eks_cluster_name" {
  value = module.aws.eks_cluster_name
}

output "eks_endpoint" {
  value = module.aws.eks_endpoint
}

output "rds_endpoint" {
  value = module.aws.rds_endpoint
}

output "database_url" {
  value     = module.aws.database_url
  sensitive = true
}

output "route53_zone_id" {
  value = module.aws.route53_zone_id
}

output "route53_name_servers" {
  value = module.aws.route53_name_servers
}
