# CI/CD Module Outputs

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.enable_cicd ? kubernetes_namespace.argocd[0].metadata[0].name : ""
}

output "argocd_release_name" {
  description = "ArgoCD Helm release name"
  value       = var.enable_cicd ? helm_release.argocd[0].metadata[0].name : ""
}

output "argocd_release_status" {
  description = "ArgoCD Helm release status"
  value       = var.enable_cicd ? helm_release.argocd[0].status : ""
}

output "argocd_release_version" {
  description = "ArgoCD Helm chart version"
  value       = var.enable_cicd ? var.argocd_chart_version : ""
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = var.enable_cicd ? "argocd-server" : ""
}

output "argocd_api_service_name" {
  description = "ArgoCD API service name"
  value       = var.enable_cicd ? "argocd-server" : ""
}

output "git_repository_url" {
  description = "Git repository URL used for GitOps"
  value       = var.git_repository_url
}

output "git_repository_branch" {
  description = "Git repository branch"
  value       = var.git_repository_branch
}

output "git_repository_path" {
  description = "Path in repository for application manifests"
  value       = var.git_repository_path
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = var.enable_cicd ? "kubectl port-forward -n ${kubernetes_namespace.argocd[0].metadata[0].name} svc/argocd-server 8080:443" : ""
}

output "argocd_ui_url" {
  description = "ArgoCD UI URL (after port-forward)"
  value       = var.enable_cicd ? "https://localhost:8080" : ""
}

output "argocd_get_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = var.enable_cicd ? "kubectl -n ${kubernetes_namespace.argocd[0].metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : ""
}

output "argocd_applications" {
  description = "ArgoCD applications deployed"
  value = var.enable_cicd ? [
    "echo-server",
    "postgres-ha"
  ] : []
}

output "argocd_get_apps_command" {
  description = "Command to get ArgoCD applications"
  value       = var.enable_cicd ? "argocd app list -n ${kubernetes_namespace.argocd[0].metadata[0].name}" : ""
}

output "argocd_get_pods_command" {
  description = "Command to get ArgoCD pods"
  value       = var.enable_cicd ? "kubectl get pods -n ${kubernetes_namespace.argocd[0].metadata[0].name}" : ""
}

output "kubectl_get_applications_command" {
  description = "Command to get Application resources"
  value       = var.enable_cicd ? "kubectl get applications -n ${kubernetes_namespace.argocd[0].metadata[0].name}" : ""
}

output "sync_policy" {
  description = "ArgoCD sync policy"
  value       = var.argocd_sync_policy
}

output "auto_prune_enabled" {
  description = "Auto-prune enabled"
  value       = var.argocd_auto_prune
}

output "self_heal_enabled" {
  description = "Self-heal enabled"
  value       = var.argocd_self_heal
}
