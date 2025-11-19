# MetalLB for Load Balancing in Kind Cluster
resource "kubernetes_namespace" "metallb_system" {
  metadata {
    name = "metallb-system"
  }
}

# Install MetalLB via Helm
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace.metallb_system.metadata[0].name
  version    = "0.13.12"

  values = [
    <<EOF
    controller:
      replicas: 1
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
    
    speaker:
      enabled: true
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
    
    prometheus:
      scrapeAnnotations: false
    EOF
  ]
}

# MetalLB IPAddressPool via Helm values
resource "helm_release" "metallb_ipaddresspool" {
  name             = "metallb-ipaddresspool"
  chart            = "${path.module}/charts/metallb-ipaddresspool"
  namespace        = kubernetes_namespace.metallb_system.metadata[0].name
  create_namespace = false

  values = [
    <<EOF
    ipAddressPools:
      - name: default
        addresses:
          - 172.18.255.200-172.18.255.250
    EOF
  ]

  depends_on = [helm_release.metallb]
}

# MetalLB L2Advertisement via Helm values
resource "helm_release" "metallb_l2advertisement" {
  name             = "metallb-l2advertisement"
  chart            = "${path.module}/charts/metallb-l2advertisement"
  namespace        = kubernetes_namespace.metallb_system.metadata[0].name
  create_namespace = false

  values = [
    <<EOF
    l2Advertisements:
      - name: default
        ipAddressPools:
          - default
    EOF
  ]

  depends_on = [helm_release.metallb_ipaddresspool]
}

# Service to expose MetalLB metrics
resource "kubernetes_service" "metallb_metrics" {
  metadata {
    name      = "metallb-metrics"
    namespace = kubernetes_namespace.metallb_system.metadata[0].name
    labels = {
      app = "metallb"
    }
  }

  spec {
    selector = {
      app       = "metallb"
      component = "controller"
    }

    port {
      name        = "metrics"
      port        = 7472
      target_port = 7472
    }

    type = "ClusterIP"
  }
}
