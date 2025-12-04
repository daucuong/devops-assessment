locals {
  common_labels = merge(
    var.common_tags,
    {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/component"  = "ingress-controller"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "project"                      = var.project_name
    }
  )
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.ingress_namespace
    labels = merge(
      local.common_labels,
      {
        "namespace-purpose" = "ingress-controller"
      }
    )
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
        # Worker configuration
        workerProcesses = var.nginx_worker_processes
        workerRlimitNofile = var.nginx_worker_rlimit_nofile
        # Rate limiting and request handling
        config = {
          "worker-processes"        = var.nginx_worker_processes
          "worker-connections"      = var.nginx_worker_connections
          "worker-rlimit-nofile"    = var.nginx_worker_rlimit_nofile
          "client-body-timeout"     = "600"
          "client-header-timeout"   = "600"
          "client-max-body-size"    = "20m"
          "upstream-keepalive-timeout" = "60"
          "upstream-keepalive-requests" = "100"
          "keep-alive"              = "75"
          "keep-alive-requests"     = "100"
        }
        # Stream configuration for TCP/UDP load balancing
        tcp = var.enable_tcp_udp_balancing ? {
          "443" = "database/postgres-primary:5432"
        } : {}
        udp = var.enable_tcp_udp_balancing ? {} : {}
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
    labels = merge(
      local.common_labels,
      {
        "app.kubernetes.io/name"       = "acme-ingress"
        "app.kubernetes.io/instance"   = var.ingress_name
        "resource-type"                = "ingress"
      }
    )
    annotations = merge(
      {
        "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "600"
        "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "600"
        "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "600"
        "nginx.ingress.kubernetes.io/proxy-body-timeout"    = "600"
      },
      var.additional_annotations
    )
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
