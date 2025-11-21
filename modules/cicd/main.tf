# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  count = var.enable_cicd ? 1 : 0
  
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/name"       = "argocd"
      "app.kubernetes.io/component"  = "cicd"
    }
  }
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  count = var.enable_cicd ? 1 : 0
  
  name             = var.argocd_release_name
  repository       = var.argocd_repository
  chart            = var.argocd_chart
  namespace        = kubernetes_namespace.argocd[0].metadata[0].name
  version          = var.argocd_chart_version
  create_namespace = false

  values = [
    yamlencode({
      global = {
        domain = "argocd.local"
      }
      
      configs = {
        params = {
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
        cm = {
          "url" = "https://argocd.local"
          "application.resourceTrackingMethod" = "annotation"
        }
      }

      server = {
        service = {
          type = "ClusterIP"
        }
      }

      redis = {
        enabled = true
      }

      controller = {
        replicas = 1
      }

      dex = {
        enabled = true
      }

      applicationSet = {
        enabled = true
      }

      notifications = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Create Git repository secret for private repos
resource "kubernetes_secret" "git_credentials" {
  count = var.enable_cicd && var.git_repository_username != "" ? 1 : 0

  metadata {
    name      = "git-credentials"
    namespace = kubernetes_namespace.argocd[0].metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type           = "git"
    url            = var.git_repository_url
    username       = var.git_repository_username
    password       = var.git_repository_password
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Applications will be created manually using kubectl or ArgoCD UI
# After ArgoCD is deployed and CRDs are installed
