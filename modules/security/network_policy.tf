# Network Policy - Restrict all traffic by default (private subnet for all components)
resource "kubernetes_network_policy" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = var.security_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "default_deny_egress" {
  metadata {
    name      = "default-deny-egress"
    namespace = var.security_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]
  }
}

# Allow DNS queries for all components
resource "kubernetes_network_policy" "allow_dns" {
  metadata {
    name      = "allow-dns"
    namespace = var.security_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      ports {
        port     = "53"
        protocol = "TCP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }

        pod_selector {
          match_labels = {
            k8s-app = "kube-dns"
          }
        }
      }
    }
  }
}

# Cert-Manager internal communication (private)
resource "kubernetes_network_policy" "cert_manager_private" {
  count = var.enable_cert_manager ? 1 : 0

  metadata {
    name      = "cert-manager-private"
    namespace = var.cert_manager_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "cert-manager"
      }
    }
    policy_types = ["Ingress", "Egress"]

    # Allow internal cert-manager communication
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.cert_manager_namespace
          }
        }
      }
    }

    # Allow outbound to other security components
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = var.security_namespace
          }
        }
      }
    }

    # Allow DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow HTTPS for certificate validation
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
  }
}

# External Secrets Operator (allow access from all components)
resource "kubernetes_network_policy" "external_secrets_allow_all" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name      = "external-secrets-allow-all"
    namespace = kubernetes_namespace.security.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "external-secrets"
      }
    }
    policy_types = ["Ingress"]

    # Allow ingress from all namespaces (webhook validation)
    ingress {
      ports {
        port     = "10250"
        protocol = "TCP"
      }
    }

    # Allow ingress from all namespaces (metrics)
    ingress {
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # Allow ingress from all namespaces (webhook)
    ingress {
      ports {
        port     = "9443"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy" "external_secrets_egress" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name      = "external-secrets-egress"
    namespace = kubernetes_namespace.security.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "external-secrets"
      }
    }
    policy_types = ["Egress"]

    # Allow DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow outbound to secret backends (AWS Secrets Manager, Azure Key Vault, etc.)
    egress {
      ports {
        port     = "443"
        protocol = "TCP"
      }

      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "169.254.169.254/32" # Block EC2 metadata
          ]
        }
      }
    }
  }
}

# Istio System (private)
resource "kubernetes_network_policy" "istio_private" {
  count = var.enable_istio ? 1 : 0

  metadata {
    name      = "istio-private"
    namespace = var.istio_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    # Allow internal Istio communication
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.istio_namespace
          }
        }
      }
    }

    # Allow from monitored namespaces
    ingress {
      from {
        pod_selector {
          match_labels = {
            "istio-injection" = "enabled"
          }
        }
      }
    }

    # Allow DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow internal mesh communication
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = var.istio_namespace
          }
        }
      }
    }

    # Allow to monitored namespaces
    egress {
      to {
        pod_selector {
          match_labels = {
            "istio-injection" = "enabled"
          }
        }
      }
    }
  }
}

# Ingress-Nginx controller network policies (allow egress to application)
resource "kubernetes_network_policy" "ingress_nginx_to_app" {
  metadata {
    name      = "ingress-nginx-to-app"
    namespace = var.ingress_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    # Allow internal ingress-nginx communication
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.ingress_namespace
          }
        }
      }
    }

    # Allow egress to application pods
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = var.app_namespace_name
          }
        }
      }
    }

    # Allow DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow to kubernetes API
    egress {
      ports {
        port     = "443"
        protocol = "TCP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }
  }
}

# Application namespace network policies
resource "kubernetes_network_policy" "app_allow_public" {
  metadata {
    name      = "app-allow-public"
    namespace = var.app_namespace_name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/component" = "application"
      }
    }
    policy_types = ["Ingress"]

    # Allow public ingress from ingress controller
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.ingress_namespace
          }
        }
      }
    }
  }
}

# Allow all egress from application (for now)
resource "kubernetes_network_policy" "app_egress_all" {
  metadata {
    name      = "app-egress-all"
    namespace = var.app_namespace_name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "allow_ingress_nginx" {
  metadata {
    name      = "allow-ingress-nginx"
    namespace = "ingress-nginx"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "ingress-nginx"
          }
        }
      }
    }
  }
}

# Database namespace network policies (private)
resource "kubernetes_network_policy" "database_private" {
  metadata {
    name      = "database-private"
    namespace = var.database_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    # Allow only from application namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.app_namespace_name
          }
        }
      }
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }
  }
}

# Monitoring namespace network policies (private)
resource "kubernetes_network_policy" "monitoring_private" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "monitoring-private"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    # Allow scraping from internal monitoring only
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.monitoring_namespace
          }
        }
      }
    }
  }
}

# Security namespace network policies (private)
resource "kubernetes_network_policy" "security_internal_only" {
  metadata {
    name      = "security-internal-only"
    namespace = var.security_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    # Allow only internal security namespace communication
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.security_namespace
          }
        }
      }
    }
  }
}
