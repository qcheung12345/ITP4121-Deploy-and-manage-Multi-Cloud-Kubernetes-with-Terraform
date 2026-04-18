resource "tls_private_key" "guestbook_tls" {
  count     = var.enable_k8s_secrets ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "guestbook_tls" {
  count = var.enable_k8s_secrets ? 1 : 0

  private_key_pem       = tls_private_key.guestbook_tls[0].private_key_pem
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
