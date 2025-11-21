resource "kubernetes_namespace" "security" {
  metadata {
    name = var.security_namespace
    labels = {
      "app.kubernetes.io/component" = "security"
    }
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  metadata {
    name = var.cert_manager_namespace
  }
}

resource "helm_release" "cert_manager" {
  count      = var.enable_cert_manager ? 1 : 0
  name       = var.cert_manager_name
  repository = var.cert_manager_repository
  chart      = var.cert_manager_chart
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name
  version    = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = "true"
  }
}
