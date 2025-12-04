output "namespace" {
  description = "Application namespace"
  value       = var.app_namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.application.name
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.application.status
}

output "release_version" {
  description = "Helm release version"
  value       = helm_release.application.version
}

output "ui_service_name" {
  description = "UI Service name"
  value       = "acme"
}

output "api_service_name" {
  description = "API Service name"
  value       = "acme-api"
}

output "service_port" {
  description = "Service port"
  value       = var.service_port
}

output "ingress_hosts" {
  description = "Ingress hosts"
  value       = [for host in var.ingress_hosts : host.host]
}

output "port_forward_command" {
  description = "Command to port-forward to the service"
  value       = "kubectl port-forward -n ${var.app_namespace} svc/${helm_release.application.name} 8080:${var.service_port}"
}

output "get_pods_command" {
  description = "Command to get pods"
  value       = "kubectl get pods -n ${var.app_namespace}"
}

output "logs_command" {
  description = "Command to view logs"
  value       = "kubectl logs -n ${var.app_namespace} -l app.kubernetes.io/name=${helm_release.application.name} -f"
}

output "helm_status_command" {
  description = "Command to check Helm release status"
  value       = "helm status ${helm_release.application.name} -n ${var.app_namespace}"
}
