resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name = var.monitoring_namespace
  }
}

resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = var.prometheus_name
  repository = var.prometheus_repository
  chart      = var.prometheus_chart
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = var.prometheus_version

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          resources = {
            requests = {
              cpu    = var.prometheus_cpu_request
              memory = var.prometheus_memory_request
            }
            limits = {
              cpu    = var.prometheus_cpu_limit
              memory = var.prometheus_memory_limit
            }
          }
        }
      }
      grafana = {
        enabled       = var.grafana_enabled
        adminPassword = var.grafana_password
      }
    })
  ]
}
