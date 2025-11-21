# CI/CD Module Variables

variable "enable_cicd" {
  description = "Enable CI/CD module (ArgoCD)"
  type        = bool
  default     = true
}

# ArgoCD Variables
variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_repository" {
  description = "Helm repository URL for ArgoCD"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "argocd_chart" {
  description = "Helm chart name for ArgoCD"
  type        = string
  default     = "argo-cd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
  default     = "5.51.6"
}

# Git Repository Variables
variable "git_repository_url" {
  description = "Git repository URL for GitOps"
  type        = string
  default     = "https://github.com/daucuong/devops-assessment.git"
}

variable "git_repository_branch" {
  description = "Git repository branch"
  type        = string
  default     = "main"
}

variable "git_repository_path" {
  description = "Path in Git repository containing application manifests"
  type        = string
  default     = "k8s"
}

variable "git_repository_username" {
  description = "Git repository username (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "git_repository_password" {
  description = "Git repository password/token (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Application Deployment Variables
variable "app_namespace_name" {
  description = "Namespace where application will be deployed"
  type        = string
  default     = "application"
}

variable "argocd_sync_policy" {
  description = "ArgoCD sync policy"
  type        = string
  default     = "automated"
}

variable "argocd_auto_prune" {
  description = "Automatically prune resources not in Git"
  type        = bool
  default     = true
}

variable "argocd_self_heal" {
  description = "Enable self-healing"
  type        = bool
  default     = true
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  default     = ""
  sensitive   = true
}
