resource "helm_release" "cnpg_operator" {
  count            = var.enable_database ? 1 : 0
  name             = "cloudnative-pg"
  repository       = var.cnpg_repository
  chart            = var.cnpg_chart
  namespace        = kubernetes_namespace.database.metadata[0].name
  version          = var.cnpg_version
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      monitoring = {
        enabled = true
      }
      certManager = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.database
  ]
}
