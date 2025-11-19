variable "argocd_domain" {
  description = "Domain for ArgoCD"
  type        = string
  default     = "argocd.local"
}

variable "repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
  default     = "https://github.com/example/devops-assessment"
}

variable "manifests_path" {
  description = "Path to Kubernetes manifests in the repository"
  type        = string
  default     = "k8s-manifests"
}
