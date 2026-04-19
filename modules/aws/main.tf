terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  name_prefix  = "${var.project_name}-aws"
  cluster_name = substr(replace("${local.name_prefix}-eks", "_", "-"), 0, 100)
  db_identifier = substr(replace("${local.name_prefix}-postgres", "_", "-"), 0, 63)
}

resource "aws_route53_zone" "this" {
  name = var.route53_domain_name

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-zone"
  })
}
