output "security_namespace" {
  description = "Security namespace"
  value       = kubernetes_namespace.security.metadata[0].name
}

output "cert_manager_namespace" {
  description = "Cert-Manager namespace"
  value       = var.enable_cert_manager ? kubernetes_namespace.cert_manager[0].metadata[0].name : null
}

output "cert_manager_release_name" {
  description = "Cert-Manager release name"
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].name : null
}

output "external_secrets_release_name" {
  description = "External Secrets Operator release name"
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].name : null
}

output "external_secrets_release_status" {
  description = "External Secrets Operator release status"
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].status : null
}

output "external_secrets_release_version" {
  description = "External Secrets Operator release version"
  value       = var.enable_external_secrets ? helm_release.external_secrets[0].version : null
}

output "istio_namespace" {
  description = "Istio namespace"
  value       = var.enable_istio ? kubernetes_namespace.istio_system[0].metadata[0].name : null
}

output "istio_release_name" {
  description = "Istio release name"
  value       = var.enable_istio ? helm_release.istio[0].name : null
}

output "istio_release_status" {
  description = "Istio release status"
  value       = var.enable_istio ? helm_release.istio[0].status : null
}

output "istio_release_version" {
  description = "Istio release version"
  value       = var.enable_istio ? helm_release.istio[0].version : null
}

output "istio_service_account" {
  description = "Istio service account name"
  value       = var.enable_istio ? kubernetes_service_account.istio[0].metadata[0].name : null
}
