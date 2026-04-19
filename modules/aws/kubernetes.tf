locals {
  database_url = format(
    "postgresql://%s:%s@%s:5432/%s",
    var.db_username,
    random_password.postgres.result,
    aws_db_instance.postgres.address,
    var.db_name,
  )
}

resource "kubernetes_secret" "guestbook_app_secret" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-app-secret"
    namespace = var.k8s_namespace
  }

  type = "Opaque"

  data = {
    DATABASE_URL = local.database_url
    SECRET_KEY   = var.app_secret_key
  }
}

resource "kubernetes_secret" "guestbook_db_secret" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-db-secret"
    namespace = var.k8s_namespace
  }

  type = "Opaque"

  data = {
    DATABASE_USER     = var.db_username
    DATABASE_PASSWORD = random_password.postgres.result
  }
}

resource "kubernetes_deployment" "guestbook_web" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-web"
    namespace = var.k8s_namespace
    labels = {
      app = "guestbook-web"
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "guestbook-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "guestbook-web"
        }
      }

      spec {
        container {
          name  = "web"
          image = var.app_image

          port {
            container_port = var.container_port
          }

          env {
            name = "AUTO_INIT_DB"
            value = "true"
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestbook_app_secret[0].metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.guestbook_app_secret[0].metadata[0].name
                key  = "SECRET_KEY"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "guestbook_web" {
  count = var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "guestbook-web"
    namespace = var.k8s_namespace
    labels = {
      app = "guestbook-web"
    }
  }

  spec {
    selector = {
      app = "guestbook-web"
    }

    port {
      port        = 80
      target_port = var.container_port
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}
