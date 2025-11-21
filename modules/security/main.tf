# cert-manager for certificate automation
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.12.0"
  values     = [file("${path.module}/cert-manager-values.yaml")]
}

# external-secrets for secret management
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "external_secrets" {
  metadata {
    name = "external-secrets-role"
  }

  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "serviceaccounts/token"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "external_secrets" {
  metadata {
    name = "external-secrets-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_secrets.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_secrets.metadata[0].name
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
  }
}

resource "kubernetes_deployment" "external_secrets" {
  metadata {
    name      = "external-secrets-controller"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    labels = {
      app = "external-secrets"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "external-secrets"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-secrets"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.external_secrets.metadata[0].name

        container {
          name  = "controller"
          image = "ghcr.io/external-secrets/external-secrets:v0.8.1"

          args = [
            "--enable-leader-election",
          ]

          resources {
            requests = {
              cpu    = "10m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  }
}

# Istio for service mesh
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_service_account" "istiod" {
  metadata {
    name      = "istiod"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "istiod" {
  metadata {
    name = "istiod"
  }

  rule {
    api_groups = ["networking.istio.io", "security.istio.io", "telemetry.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "services", "endpoints", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "istiod" {
  metadata {
    name = "istiod"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.istiod.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.istiod.metadata[0].name
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }
}

resource "kubernetes_deployment" "istiod" {
  metadata {
    name      = "istiod"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
    labels = {
      app = "istiod"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "istiod"
      }
    }

    template {
      metadata {
        labels = {
          app = "istiod"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.istiod.metadata[0].name

        container {
          name  = "istiod"
          image = "docker.io/istio/pilot:1.18.0"

          args = [
            "discovery",
            "--monitoringAddr=:15014",
            "--grpcAddr=:15010",
            "--httpsAddr=:15017",
          ]

          port {
            container_port = 15010
            name           = "grpc-xds"
          }

          port {
            container_port = 15014
            name           = "http-monitoring"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
