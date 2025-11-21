resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

resource "kubernetes_service_account" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "ingress-nginx"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_config_map" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/name"      = "ingress-nginx"
    }
  }

  data = {
    # Access logging configuration
    #"access-log-path"   = "/var/log/nginx/access.log"
    "access-log-format" = <<EOF
{
  "time": "$time_iso8601",
  "remote_addr": "$remote_addr",
  "remote_user": "$remote_user",
  "request": "$request",
  "status": "$status",
  "body_bytes_sent": "$body_bytes_sent",
  "http_referer": "$http_referer",
  "http_user_agent": "$http_user_agent",
  "request_length": "$request_length",
  "request_time": "$request_time",
  "upstream_response_time": "$upstream_response_time",
  "upstream_addr": "$upstream_addr",
  "upstream_status": "$upstream_status",
  "host": "$host",
  "request_id": "$request_id"
}
EOF

    # Keep-alive and timeout configurations
    "keep-alive"                     = "75"
    "keep-alive-requests"            = "1000"
    "upstream-keepalive-connections" = "32"

    # Client timeout settings
    "client-max-body-size"  = "50m"
    "client-body-timeout"   = "12"
    "client-header-timeout" = "12"
    "send-timeout"          = "10"

    # Proxy timeout settings
    "proxy-connect-timeout"       = "5"
    "proxy-send-timeout"          = "30"
    "proxy-read-timeout"          = "30"
    "proxy-next-upstream-timeout" = "5"

    # Buffer size configurations
    "proxy-buffers"           = "4 256k"
    "proxy-buffer-size"       = "128k"
    "proxy-busy-buffers-size" = "256k"

    # Connection limits
    "max-worker-connections" = "65536"
    "worker-processes"       = "auto"

    # Security headers
    "add-headers"                   = "ingress-nginx/custom-headers"
    "enable-underscores-in-headers" = "true"

    # Health check configuration
    "health-check-path" = "/healthz"

    # Rate limiting (basic)
    "rate-limit"        = "100"
    "rate-limit-window" = "1m"
  }
}

# Custom headers ConfigMap for security headers
resource "kubernetes_config_map" "custom_headers" {
  metadata {
    name      = "custom-headers"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  data = {
    "X-Frame-Options"           = "DENY"
    "X-Content-Type-Options"    = "nosniff"
    "X-XSS-Protection"          = "1; mode=block"
    "Strict-Transport-Security" = "max-age=31536000; includeSubDomains"
    "Content-Security-Policy"   = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    "Referrer-Policy"           = "strict-origin-when-cross-origin"
    "Permissions-Policy"        = "geolocation=(), microphone=(), camera=()"
  }
}

# Fluent Bit for log shipping from ingress to Elasticsearch
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-config"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  data = {
    "fluent-bit.conf" = <<EOF
[SERVICE]
    Flush         5
    Log_Level     info
    Daemon        off

[INPUT]
    Name              tail
    Path              /var/log/containers/*ingress-nginx-controller*.log
    Parser            cri
    Tag               nginx.ingress
    Refresh_Interval  5

[OUTPUT]
    Name  es
    Match nginx.ingress
    Host  elasticsearch.logging.svc.cluster.local
    Port  9200
    Index nginx-access
    Suppress_Type_Name On
EOF

    "parsers.conf" = <<EOF
[PARSER]
    Name cri
    Format cri
EOF
  }
}

# Fluent Bit DaemonSet for log collection
resource "kubernetes_service_account" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "fluent_bit" {
  metadata {
    name = "fluent-bit-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent_bit" {
  metadata {
    name = "fluent-bit-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluent_bit.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fluent_bit.metadata[0].name
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_daemonset" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          app = "fluent-bit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluent_bit.metadata[0].name

        container {
          name  = "fluent-bit"
          image = "fluent/fluent-bit:2.1"

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc"
          }

          volume_mount {
            name       = "logs"
            mount_path = "/var/log/nginx"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "25Mi"
            }

            limits = {
              cpu    = "50m"
              memory = "60Mi"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata[0].name
          }
        }

        volume {
          name = "logs"

          host_path {
            path = "/var/log/nginx"
            type = "DirectoryOrCreate"
          }
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Equal"
          effect   = "NoSchedule"
        }

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Equal"
          effect   = "NoSchedule"
        }

        security_context {
          run_as_user  = 101
          run_as_group = 101
          fs_group     = 101
        }
      }
    }
  }
}

resource "kubernetes_service" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/name"      = "ingress-nginx"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/name"      = "ingress-nginx"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "80"
      node_port   = 30080
    }

    port {
      name        = "https"
      port        = 443
      target_port = "443"
      node_port   = 30443
    }

    type = "NodePort"
  }
}

resource "kubernetes_config_map" "tcp_services" {
  metadata {
    name      = "tcp-services"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_config_map" "udp_services" {
  metadata {
    name      = "udp-services"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
}

resource "kubernetes_deployment" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/name"      = "ingress-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/component" = "controller"
          "app.kubernetes.io/instance"  = "ingress-nginx"
          "app.kubernetes.io/name"      = "ingress-nginx"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.ingress_nginx.metadata[0].name

        container {
          name  = "controller"
          image = "registry.k8s.io/ingress-nginx/controller:v1.8.1"

          args = [
            "/nginx-ingress-controller",
            "--configmap=$(POD_NAMESPACE)/ingress-nginx-controller",
            "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services",
            "--udp-services-configmap=$(POD_NAMESPACE)/udp-services",
            "--publish-service=$(POD_NAMESPACE)/ingress-nginx-controller",
            "--annotations-prefix=nginx.ingress.kubernetes.io",
          ]

          port {
            container_port = 80
            name           = "http"
            protocol       = "TCP"
          }

          port {
            container_port = 443
            name           = "https"
            protocol       = "TCP"
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "10254"
            }

            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "10254"
            }

            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }

          # volume_mount {
          #   name       = "nginx-logs"
          #   mount_path = "/var/log/nginx"
          # }

          resources {
            requests = {
              cpu    = "100m"
              memory = "90Mi"
            }
          }
        }

        # volume {
        #   name = "nginx-logs"

        #   host_path {
        #     path = "/var/log/nginx"
        #     type = "DirectoryOrCreate"
        #   }
        # }

        node_selector = {
          "ingress-ready" = "true"
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Equal"
          effect   = "NoSchedule"
        }

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Equal"
          effect   = "NoSchedule"
        }

        security_context {
          run_as_user  = 101
          run_as_group = 101
          fs_group     = 101
        }
      }
    }
  }
}
