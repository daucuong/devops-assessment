resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.46.0"

  values = [
    <<EOF
    server:
      service:
        type: ClusterIP
      ingress:
        enabled: true
        hosts:
          - argocd.local
        paths:
          - /
        tls:
          - secretName: argocd-tls
            hosts:
              - argocd.local
    configs:
      cm:
        timeout.reconciliation: 30s
      rbac:
        policy.csv: |
          g, argocd-admin, role:admin
        policy.default: role:readonly
    applications:
      acme-app:
        namespace: ${kubernetes_namespace.argocd.metadata[0].name}
        finalizers:
          - resources-finalizer.argoproj.io
        project: default
        source:
          repoURL: https://github.com/example/devops-assessment
          targetRevision: HEAD
          path: k8s-manifests
        destination:
          server: https://kubernetes.default.svc
          namespace: acme
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
    EOF
  ]
}
