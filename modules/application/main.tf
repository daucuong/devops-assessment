resource "kubernetes_namespace" "app" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.app_namespace
  }
}

resource "helm_release" "application" {
  name      = var.release_name
  chart     = var.chart_path
  namespace = var.app_namespace

  values = [
    yamlencode({
      ui = {
        image = {
          repository = var.image_repository
          tag        = var.image_tag
        }
        replicas = var.replicas
      }
      api = {
        image = {
          repository = var.api_image_repository
          tag        = var.api_image_tag
        }
        replicas = var.api_replicas
      }
      image = {
        pullPolicy = var.image_pull_policy
      }
      service = {
        type = var.service_type
      }
      ingress = {
        enabled      = var.enable_ingress
        className    = var.ingress_class
        annotations  = var.ingress_annotations
        hosts        = var.enable_ingress ? var.ingress_hosts : []
        tls          = var.ingress_tls
      }
      resources = {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }
      autoscaling = {
        enabled      = var.autoscaling_enabled
        minReplicas  = var.autoscaling_min_replicas
        maxReplicas  = var.autoscaling_max_replicas
        metrics      = var.autoscaling_metrics
      }
    })
  ]

  depends_on = [kubernetes_namespace.app]
}
