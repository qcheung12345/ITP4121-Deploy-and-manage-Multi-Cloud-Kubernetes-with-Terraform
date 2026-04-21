resource "azurerm_log_analytics_workspace" "this" {
  count               = 0 # Disabled due to subscription region restrictions
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

locals {
  actual_database_url = var.enable_managed_postgres ? format(
    "postgresql://%s:%s@%s:5432/%s",
    var.postgres_user_name,
    replace(replace(replace(replace(random_password.postgres[0].result, "@", "%40"), "+", "%2B"), "(", "%28"), ")", "%29"),
    azurerm_postgresql_flexible_server.postgres[0].fqdn,
    var.postgres_database_name,
  ) : "postgresql://app_user:change-me@postgres.guestbook.svc.cluster.local:5432/app_db"

  actual_database_user     = var.enable_managed_postgres ? var.postgres_user_name : "app_user"
  actual_database_password = var.enable_managed_postgres ? random_password.postgres[0].result : "change-me"
}

# Kubernetes Secrets for database and application
resource "kubernetes_secret" "guestbook_app_secret" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-app-secret"
    namespace = "guestbook"
  }

  type = "Opaque"

  data = {
    DATABASE_URL = local.actual_database_url
    SECRET_KEY   = "change-me-before-prod"
  }
}

resource "kubernetes_secret" "guestbook_db_secret" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-db-secret"
    namespace = "guestbook"
  }

  type = "Opaque"

  data = {
    DATABASE_USER     = local.actual_database_user
    DATABASE_PASSWORD = local.actual_database_password
  }
}

# Kubernetes Ingress for L7 routing with SSL/TLS
resource "kubernetes_ingress_v1" "guestbook_web" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-web"
    namespace = "guestbook"
    annotations = {
      "cert.acme.sh/enabled" = "true"
    }
  }

  spec {
    ingress_class_name = "azure-application-gateway"

    tls {
      hosts       = ["guestbook.example.com"]
      secret_name = "guestbook-tls"
    }

    rule {
      host = "guestbook.example.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

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

# TLS Certificate Secret for Ingress
resource "kubernetes_secret" "guestbook_tls" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-tls"
    namespace = "guestbook"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.guestbook_tls[0].cert_pem
    "tls.key" = tls_private_key.guestbook_tls[0].private_key_pem
  }
}

# TLS private key for self-signed certificate
resource "tls_private_key" "guestbook_tls" {
  count     = var.enable_k8s_resources ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Self-signed certificate
resource "tls_self_signed_cert" "guestbook_tls" {
  count = var.enable_k8s_resources ? 1 : 0

  private_key_pem       = tls_private_key.guestbook_tls[0].private_key_pem
  validity_period_hours = 8760

  subject {
    common_name  = "guestbook.example.com"
    organization = "ITP4121"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}