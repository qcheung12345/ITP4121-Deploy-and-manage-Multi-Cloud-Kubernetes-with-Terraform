provider "kubernetes" {
  config_path    = fileexists(pathexpand(var.kubeconfig_path)) ? pathexpand(var.kubeconfig_path) : null
  config_context = var.kubeconfig_context
}

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

resource "kubernetes_secret" "guestbook_app_secret" {
  count = var.enable_k8s_secrets ? 1 : 0

  metadata {
    name      = "guestbook-app-secret"
    namespace = var.k8s_namespace
  }

  type = "Opaque"

  data = {
    DATABASE_URL = local.effective_app_database_url
    SECRET_KEY   = var.app_secret_key
  }
}

resource "kubernetes_secret" "guestbook_tls" {
  count = var.enable_k8s_secrets ? 1 : 0

  metadata {
    name      = "guestbook-tls"
    namespace = var.k8s_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.guestbook_tls[0].cert_pem
    "tls.key" = tls_private_key.guestbook_tls[0].private_key_pem
  }
}
