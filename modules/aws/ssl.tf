resource "tls_private_key" "flask_tls" {
  count     = var.enable_k8s_resources ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "flask_tls" {
  count = var.enable_k8s_resources ? 1 : 0

  private_key_pem       = tls_private_key.flask_tls[0].private_key_pem
  validity_period_hours = 8760

  subject {
    common_name  = var.tls_common_name
    organization = "ITP4121"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret" "flask_tls_secret" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "flask-tls-secret"
    namespace = var.k8s_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.flask_tls[0].cert_pem
    "tls.key" = tls_private_key.flask_tls[0].private_key_pem
  }
}

# AWS ACM Certificate for ALB (references self-signed cert)
resource "aws_acm_certificate" "guestbook" {
  private_key          = try(tls_private_key.flask_tls[0].private_key_pem, "")
  certificate_body     = try(tls_self_signed_cert.flask_tls[0].cert_pem, "")
  certificate_chain    = try(tls_self_signed_cert.flask_tls[0].cert_pem, "")
  validation_method    = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "guestbook-certificate"
  }
}
