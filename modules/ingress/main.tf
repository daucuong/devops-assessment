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
        # High availability configuration
        replicaCount = 2
        # Pod disruption budget to ensure availability during maintenance
        podDisruptionBudget = {
          enabled = true
          minAvailable = 1
        }
        # Affinity rules for pod distribution
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key      = "app.kubernetes.io/name"
                        operator = "In"
                        values   = ["ingress-nginx"]
                      }
                    ]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
        # Enable metrics for monitoring
        metrics = {
          enabled = true
        }
        # Security context
        securityContext = {
          runAsNonRoot = true
          readOnlyRootFilesystem = true
        }
        # Rate limiting and request handling
        config = {
          "client-body-timeout"      = "600"
          "client-header-timeout"    = "600"
          "client-max-body-size"     = "20m"
          "upstream-keepalive-timeout" = "60"
          "upstream-keepalive-requests" = "100"
          "keep-alive"               = "75"
          "keep-alive-requests"      = "100"
        }
        # Logging configuration
        logs = {
          enabled = var.enable_logging
          main = {
            enabled = var.enable_logging
            format  = var.log_format_main
          }
        }
        # Access log format for upstream (detailed request information)
        logFormatUpstream = var.log_format_upstream
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = var.ingress_name
    namespace = var.app_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "600"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "600"
      "nginx.ingress.kubernetes.io/proxy-body-timeout"    = "600"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # TLS configuration
    tls {
      hosts       = ["www.acme.com"]
      secret_name = "acme-tls"
    }

    # Single host rule with path-based routing
    rule {
      host = "www.acme.com"

      http {
        # API Route: /api/* -> acme-api service
        path {
          path      = "/api"
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

        # UI Route: / -> acme service (catch-all)
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
  }

  depends_on = [helm_release.nginx_ingress]
}
