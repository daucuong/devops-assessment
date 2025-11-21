output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = var.enable_monitoring ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "prometheus_release_name" {
  description = "Prometheus release name"
  value       = var.enable_monitoring ? helm_release.prometheus[0].name : null
}

output "prometheus_release_status" {
  description = "Prometheus release status"
  value       = var.enable_monitoring ? helm_release.prometheus[0].status : null
}

output "prometheus_release_version" {
  description = "Prometheus release version"
  value       = var.enable_monitoring ? helm_release.prometheus[0].version : null
}

output "grafana_endpoint" {
  description = "Grafana access endpoint"
  value       = var.enable_monitoring ? "kubectl port-forward -n ${kubernetes_namespace.monitoring[0].metadata[0].name} svc/prometheus-grafana 3000:80" : null
}

output "prometheus_endpoint" {
  description = "Prometheus access endpoint"
  value       = var.enable_monitoring ? "kubectl port-forward -n ${kubernetes_namespace.monitoring[0].metadata[0].name} svc/prometheus-kube-prometheus-prometheus 9090:9090" : null
}

output "grafana_password" {
  description = "Grafana admin password (use 'admin' as username)"
  value       = var.enable_monitoring ? var.grafana_password : null
  sensitive   = true
}
