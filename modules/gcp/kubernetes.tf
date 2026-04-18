resource "kubernetes_secret" "guestbook_app_secret" {
  count = var.enable_k8s_secrets ? 1 : 0

  metadata {
    name      = "guestbook-app-secret"
    namespace = var.k8s_namespace
  }

  type = "Opaque"

  data = {
    DATABASE_URL = var.effective_app_database_url
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
