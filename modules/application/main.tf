resource "kubernetes_namespace" "app" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.app_namespace
  }
}

locals {
  # Build ingress hosts for echo-server Helm chart (expects simple path strings, not objects)
  default_hosts = [
    {
      host  = "echo-server.local"
      paths = ["/"]
    }
  ]
  
  # Convert path objects to simple strings if provided
  ingress_hosts = length(var.ingress_hosts) > 0 && length(var.ingress_hosts[0].paths) > 0 ? [
    for host in var.ingress_hosts : {
      host  = host.host
      paths = [for path in host.paths : path.path]
    }
  ] : local.default_hosts
}

resource "helm_release" "echo_server" {
  name       = var.release_name
  repository = var.repository
  chart      = var.chart
  namespace  = var.app_namespace
  version    = var.chart_version

  set {
    name  = "replicaCount"
    value = var.replicas
  }

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "image.pullPolicy"
    value = var.image_pull_policy
  }

  set {
    name  = "service.type"
    value = var.service_type
  }

  set {
    name  = "service.port"
    value = var.service_port
  }

  set {
    name  = "ingress.enabled"
    value = tostring(var.enable_ingress)
  }

  set {
    name  = "ingress.ingressClassName"
    value = var.ingress_class
  }

  set {
    name  = "resources.requests.cpu"
    value = var.cpu_request
  }

  set {
    name  = "resources.requests.memory"
    value = var.memory_request
  }

  set {
    name  = "resources.limits.cpu"
    value = var.cpu_limit
  }

  set {
    name  = "resources.limits.memory"
    value = var.memory_limit
  }

  values = [
    yamlencode({
      ingress = {
        annotations = var.ingress_annotations
        hosts       = var.enable_ingress ? local.ingress_hosts : []
        tls         = var.ingress_tls
      }
      env = var.environment_variables
    })
  ]

  depends_on = [kubernetes_namespace.app]
}
