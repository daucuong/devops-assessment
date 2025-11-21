resource "kubernetes_service_account" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name      = var.external_secrets_name
    namespace = kubernetes_namespace.security.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name = var.external_secrets_name
  }

  rule {
    api_groups = ["secretstores.external-secrets.io"]
    resources  = ["secretstores", "clustersecretstores"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["externalsecrets", "externalsecrets/status"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  metadata {
    name = var.external_secrets_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_secrets[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_secrets[0].metadata[0].name
    namespace = kubernetes_namespace.security.metadata[0].name
  }
}

resource "helm_release" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  name       = var.external_secrets_name
  repository = var.external_secrets_repository
  chart      = var.external_secrets_chart
  namespace  = kubernetes_namespace.security.metadata[0].name
  version    = var.external_secrets_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_secrets[0].metadata[0].name
  }

  depends_on = [
    kubernetes_cluster_role_binding.external_secrets
  ]
}
