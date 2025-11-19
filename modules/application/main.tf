# ConfigMap for environment variables
resource "kubernetes_config_map" "app_env" {
  metadata {
    name      = "app-env"
    namespace = var.app_namespace
  }

  data = {
    POSTGRES_URL = "postgresql://postgres:password@postgres-service.acme.svc.cluster.local:5432/acme_db"
    METRICS_URL  = "http://prometheus-service.acme.svc.cluster.local:80"
  }
}

# UI Deployment
resource "kubernetes_deployment" "ui" {
  metadata {
    name      = "ui"
    namespace = var.app_namespace
  }

  spec {
    replicas = var.ui_replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }

    selector {
      match_labels = {
        app = "ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "ui"
        }
      }

      spec {
        container {
          name  = "ui"
          image = var.ui_image

          port {
            container_port = 80
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ui" {
  metadata {
    name      = "ui-service"
    namespace = var.app_namespace
  }

  spec {
    selector = {
      app = "ui"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# Ingress for UI
resource "kubernetes_ingress_v1" "ui" {
  metadata {
    name      = "ui-ingress"
    namespace = var.app_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ui_domain]
      secret_name = "ui-tls"
    }

    rule {
      host = var.ui_domain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.ui.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Ingress for ArgoCD (from cicd module)
resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["argocd.local"]
      secret_name = "argocd-tls"
    }

    rule {
      host = "argocd.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Ingress for Jaeger (from apm module)
resource "kubernetes_ingress_v1" "jaeger" {
  metadata {
    name      = "jaeger-ingress"
    namespace = "observability"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["jaeger.local"]
      secret_name = "jaeger-tls"
    }

    rule {
      host = "jaeger.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "jaeger-query"
              port {
                number = 16686
              }
            }
          }
        }
      }
    }
  }
}

# Ingress for Kiali (from apm module)
resource "kubernetes_ingress_v1" "kiali" {
  metadata {
    name      = "kiali-ingress"
    namespace = "observability"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["kiali.local"]
      secret_name = "kiali-tls"
    }

    rule {
      host = "kiali.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kiali"
              port {
                number = 20001
              }
            }
          }
        }
      }
    }
  }
}

# Database Network Policy - Only API can access PostgreSQL
resource "kubernetes_network_policy" "db_policy" {
  metadata {
    name      = "db-network-policy"
    namespace = var.app_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "postgres"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "api"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    # Allow DNS resolution
    ingress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }
  }
}

# Metrics Network Policy - Allow internal monitoring access
resource "kubernetes_network_policy" "metrics_policy" {
  metadata {
    name      = "metrics-network-policy"
    namespace = var.app_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "prometheus"
      }
    }

    policy_types = ["Ingress"]

    # Allow API access for application metrics
    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "api"
          }
        }
      }

      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    # Allow monitoring namespace access (Prometheus Operator, etc.)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "monitoring"
          }
        }
      }

      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    # Allow observability namespace access (Jaeger, Kiali, etc.)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "observability"
          }
        }
      }

      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    # Allow DNS resolution
    ingress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }
  }
}

# API Network Policy - Allow necessary internal and external access
resource "kubernetes_network_policy" "api_policy" {
  metadata {
    name      = "api-network-policy"
    namespace = var.app_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "api"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from ingress controller
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "ingress-nginx"
          }
        }
      }

      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # Allow internal communication (UI, etc.)
    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "ui"
          }
        }
      }

      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # Allow egress to database
    egress {
      to {
        pod_selector {
          match_labels = {
            app = "postgres"
          }
        }
      }

      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    # Allow egress to metrics
    egress {
      to {
        pod_selector {
          match_labels = {
            app = "prometheus"
          }
        }
      }

      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    # Allow egress to DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow egress to external services (for API calls)
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }
    }
  }
}

# UI Network Policy - Allow necessary access
resource "kubernetes_network_policy" "ui_policy" {
  metadata {
    name      = "ui-network-policy"
    namespace = var.app_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "ui"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from ingress controller
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "ingress-nginx"
          }
        }
      }

      ports {
        port     = "80"
        protocol = "TCP"
      }
    }

    # Allow egress to API
    egress {
      to {
        pod_selector {
          match_labels = {
            app = "api"
          }
        }
      }

      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # Allow egress to DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow egress to external services (for static assets, etc.)
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }
    }
  }
}

# Default deny policy for all pods in the namespace
resource "kubernetes_network_policy" "default_deny_all" {
  metadata {
    name      = "default-deny-all"
    namespace = var.app_namespace
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    # Deny all ingress by default
    ingress {}

    # Allow DNS egress
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow egress to Kubernetes API
    egress {
      ports {
        port     = "443"
        protocol = "TCP"
      }

      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    # Allow egress to external services
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }
    }
  }
}
