resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.ingress_namespace
  }
}

resource "helm_release" "nginx_ingress" {
  name       = var.nginx_ingress_name
  repository = var.nginx_ingress_repository
  chart      = var.nginx_ingress_chart
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = var.nginx_ingress_version

  values = [
    yamlencode({
      controller = {
        service = {
          type = var.nginx_service_type
        }
        resources = {
          requests = {
            cpu    = var.nginx_cpu_request
            memory = var.nginx_memory_request
          }
          limits = {
            cpu    = var.nginx_cpu_limit
            memory = var.nginx_memory_limit
          }
        }
      }
    })
  ]
}
