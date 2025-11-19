resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
    labels = {
      name = "observability"
    }
  }
}

# Jaeger for distributed tracing
resource "helm_release" "jaeger" {
  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  version    = "0.71.0"

  values = [
    file("${path.module}/jaeger-values.yaml")
  ]
}

# Kiali for service mesh observability (integrates with Istio)
resource "helm_release" "kiali" {
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  version    = "1.73.0"

  values = [
    file("${path.module}/kiali-values.yaml")
  ]

  depends_on = [helm_release.jaeger]
}
