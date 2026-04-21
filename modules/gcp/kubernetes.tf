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

resource "kubernetes_secret" "guestbook_db_secret" {
  count = var.enable_k8s_secrets ? 1 : 0

  metadata {
    name      = "guestbook-db-secret"
    namespace = var.k8s_namespace
  }

  type = "Opaque"

  data = {
    DATABASE_USER     = google_sql_user.app[0].name
    DATABASE_PASSWORD = random_password.postgres[0].result
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

# L7 Ingress for Google Cloud Load Balancer
resource "kubernetes_ingress_v1" "guestbook_web" {
  count = var.enable_k8s_secrets ? 1 : 0

  metadata {
    name      = "guestbook-web"
    namespace = var.k8s_namespace
    annotations = {
      "kubernetes.io/ingress.class"                = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = "guestbook-ip"
      "ingress.gcp.kubernetes.io/pre-shared-cert"  = "guestbook-ssl-cert"
    }
  }

  spec {
    ingress_class_name = "gce"

    tls {
      hosts       = ["guestbook.example.com"]
      secret_name = kubernetes_secret.guestbook_tls[0].metadata[0].name
    }

    rule {
      host = "guestbook.example.com"

      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = "guestbook-web"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.guestbook_tls]
}
