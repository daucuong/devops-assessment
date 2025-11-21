resource "kubernetes_namespace" "istio_system" {
  count = var.enable_istio ? 1 : 0
  metadata {
    name = "istio-system"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_service_account" "istio" {
  count = var.enable_istio ? 1 : 0
  metadata {
    name      = var.istio_service_account_name
    namespace = kubernetes_namespace.istio_system[0].metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-name"      = var.istio_name
      "meta.helm.sh/release-namespace" = kubernetes_namespace.istio_system[0].metadata[0].name
    }
  }
}

resource "kubernetes_cluster_role" "istio" {
  count = var.enable_istio ? 1 : 0
  metadata {
    name = var.istio_name
  }

  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["virtualservices", "destinationrules", "gateways", "serviceentries"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["security.istio.io"]
    resources  = ["authorizationpolicies", "peerauthentications", "requestauthentications"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["telemetry.istio.io"]
    resources  = ["telemetries"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/logs"]
    verbs      = ["get"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "istio" {
  count = var.enable_istio ? 1 : 0
  metadata {
    name = var.istio_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.istio[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.istio[0].metadata[0].name
    namespace = kubernetes_namespace.istio_system[0].metadata[0].name
  }
}

resource "helm_release" "istio" {
  count            = var.enable_istio ? 1 : 0
  name             = var.istio_name
  repository       = var.istio_repository
  chart            = var.istio_chart
  namespace        = kubernetes_namespace.istio_system[0].metadata[0].name
  version          = var.istio_version
  create_namespace = false

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.istio[0].metadata[0].name
      }
      global = {
        istio_namespace = kubernetes_namespace.istio_system[0].metadata[0].name
      }
      meshConfig = {
        ingressNamespace = kubernetes_namespace.istio_system[0].metadata[0].name
      }
    })
  ]

  depends_on = [
    kubernetes_cluster_role_binding.istio
  ]
}
