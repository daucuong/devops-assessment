resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.ingress_namespace
  }
}

resource "helm_release" "nginx_ingress" {
  name       = var.nginx_ingress_name
  repository = var.nginx_ingress_repository
  chart      = var.nginx_ingress_chart
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = var.nginx_ingress_version

  values = [
    yamlencode({
      controller = {
        service = {
          type = var.nginx_service_type
        }
        resources = {
          requests = {
            cpu    = var.nginx_cpu_request
            memory = var.nginx_memory_request
          }
          limits = {
            cpu    = var.nginx_cpu_limit
            memory = var.nginx_memory_limit
          }
        }
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = var.ingress_name
    namespace = var.app_namespace
  }

  spec {
    ingress_class_name = "nginx"

    # UI Route: www.acme.com -> acme service
    rule {
      host = "www.acme.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "acme"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }

    # API Route: api.acme.com -> acme-api service
    rule {
      host = "api.acme.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "acme-api"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.nginx_ingress]
}
