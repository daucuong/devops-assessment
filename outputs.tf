# NGINX Ingress Outputs
output "nginx_ingress_namespace" {
  description = "NGINX Ingress namespace"
  value       = module.ingress.nginx_ingress_namespace
}

output "nginx_ingress_release_name" {
  description = "NGINX Ingress release name"
  value       = module.ingress.nginx_ingress_release_name
}

# Security Module Outputs
output "security_namespace" {
  description = "Security namespace"
  value       = module.security.security_namespace
}

# Cert-Manager Outputs
output "cert_manager_namespace" {
  description = "Cert-Manager namespace"
  value       = module.security.cert_manager_namespace
}

output "cert_manager_release_name" {
  description = "Cert-Manager release name"
  value       = module.security.cert_manager_release_name
}

# External Secrets Outputs
output "external_secrets_release_name" {
  description = "External Secrets Operator release name"
  value       = module.security.external_secrets_release_name
}

output "external_secrets_release_status" {
  description = "External Secrets Operator release status"
  value       = module.security.external_secrets_release_status
}

output "external_secrets_release_version" {
  description = "External Secrets Operator release version"
  value       = module.security.external_secrets_release_version
}

# Istio Outputs
output "istio_namespace" {
  description = "Istio namespace"
  value       = module.security.istio_namespace
}

output "istio_release_name" {
  description = "Istio release name"
  value       = module.security.istio_release_name
}

output "istio_release_status" {
  description = "Istio release status"
  value       = module.security.istio_release_status
}

output "istio_release_version" {
  description = "Istio release version"
  value       = module.security.istio_release_version
}

output "istio_service_account" {
  description = "Istio service account name"
  value       = module.security.istio_service_account
}

# Database Outputs
output "database_namespace" {
  description = "Database namespace"
  value       = module.database.database_namespace
}

output "postgres_cluster_name" {
  description = "PostgreSQL cluster name"
  value       = module.database.postgres_cluster_name
}

output "postgres_service_fqdn" {
  description = "PostgreSQL service FQDN for internal connections"
  value       = module.database.postgres_service_fqdn
}

output "postgres_instances" {
  description = "Number of PostgreSQL instances in HA cluster"
  value       = module.database.postgres_instances
}

output "postgres_rto_minutes" {
  description = "Recovery Time Objective"
  value       = module.database.rto_minutes
}

output "postgres_rpo_minutes" {
  description = "Recovery Point Objective"
  value       = module.database.rpo_minutes
}

output "dr_strategy" {
  description = "Disaster Recovery strategy summary"
  value       = module.database.dr_strategy
}

# Monitoring Outputs
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = module.monitoring.monitoring_namespace
}

output "prometheus_release_name" {
  description = "Prometheus release name"
  value       = module.monitoring.prometheus_release_name
}

output "prometheus_release_status" {
  description = "Prometheus release status"
  value       = module.monitoring.prometheus_release_status
}

output "prometheus_release_version" {
  description = "Prometheus release version"
  value       = module.monitoring.prometheus_release_version
}

output "grafana_endpoint" {
  description = "Grafana access endpoint"
  value       = module.monitoring.grafana_endpoint
}

output "prometheus_endpoint" {
  description = "Prometheus access endpoint"
  value       = module.monitoring.prometheus_endpoint
}

output "grafana_password" {
  description = "Grafana admin password (use 'admin' as username)"
  value       = module.monitoring.grafana_password
  sensitive   = true
}

# Echo Server Application Outputs
output "app_namespace" {
  description = "Echo Server namespace"
  value       = module.application.namespace
}

output "app_release_name" {
  description = "Echo Server Helm release name"
  value       = module.application.release_name
}

output "app_release_status" {
  description = "Echo Server Helm release status"
  value       = module.application.release_status
}

output "app_service_name" {
  description = "Echo Server service name"
  value       = module.application.service_name
}

output "app_service_port" {
  description = "Echo Server service port"
  value       = module.application.service_port
}

output "app_ingress_hosts" {
  description = "Echo Server Ingress hosts"
  value       = module.application.ingress_hosts
}

output "app_port_forward_command" {
  description = "Command to port-forward to Echo Server"
  value       = module.application.port_forward_command
}

output "app_get_pods_command" {
  description = "Command to view Echo Server pods"
  value       = module.application.get_pods_command
}

output "app_logs_command" {
  description = "Command to view Echo Server logs"
  value       = module.application.logs_command
}

output "app_helm_status_command" {
  description = "Command to check Echo Server Helm status"
  value       = module.application.helm_status_command
}

# CI/CD Module Outputs (ArgoCD)
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.cicd.argocd_namespace
}

output "argocd_release_name" {
  description = "ArgoCD Helm release name"
  value       = module.cicd.argocd_release_name
}

output "argocd_release_status" {
  description = "ArgoCD Helm release status"
  value       = module.cicd.argocd_release_status
}

output "argocd_release_version" {
  description = "ArgoCD Helm chart version"
  value       = module.cicd.argocd_release_version
}

output "git_repository_url" {
  description = "Git repository URL for GitOps"
  value       = module.cicd.git_repository_url
}

output "git_repository_branch" {
  description = "Git repository branch"
  value       = module.cicd.git_repository_branch
}

output "git_repository_path" {
  description = "Path in repository for application manifests"
  value       = module.cicd.git_repository_path
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = module.cicd.argocd_port_forward_command
}

output "argocd_ui_url" {
  description = "ArgoCD UI URL (after port-forward)"
  value       = module.cicd.argocd_ui_url
}

output "argocd_get_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.cicd.argocd_get_admin_password_command
}

output "argocd_applications" {
  description = "ArgoCD applications deployed"
  value       = module.cicd.argocd_applications
}

output "argocd_get_apps_command" {
  description = "Command to get ArgoCD applications"
  value       = module.cicd.argocd_get_apps_command
}

output "argocd_get_pods_command" {
  description = "Command to get ArgoCD pods"
  value       = module.cicd.argocd_get_pods_command
}

output "kubectl_get_applications_command" {
  description = "Command to get Application resources"
  value       = module.cicd.kubectl_get_applications_command
}

output "argocd_sync_policy" {
  description = "ArgoCD sync policy"
  value       = module.cicd.sync_policy
}

output "argocd_auto_prune_enabled" {
  description = "Auto-prune enabled"
  value       = module.cicd.auto_prune_enabled
}

output "argocd_self_heal_enabled" {
  description = "Self-heal enabled"
  value       = module.cicd.self_heal_enabled
}

# Observability Module Outputs (OpenTelemetry, Jaeger, Tempo)
output "observability_namespace" {
  description = "Observability namespace"
  value       = module.observability.observability_namespace
}

output "otel_collector_enabled" {
  description = "OpenTelemetry Collector enabled"
  value       = module.observability.otel_collector_enabled
}

output "otel_collector_release_name" {
  description = "OpenTelemetry Collector Helm release name"
  value       = module.observability.otel_collector_release_name
}

output "otel_collector_otlp_grpc_endpoint" {
  description = "OpenTelemetry Collector OTLP gRPC endpoint"
  value       = module.observability.otel_collector_otlp_grpc_endpoint
}

output "otel_collector_otlp_http_endpoint" {
  description = "OpenTelemetry Collector OTLP HTTP endpoint"
  value       = module.observability.otel_collector_otlp_http_endpoint
}

output "jaeger_enabled" {
  description = "Jaeger enabled"
  value       = module.observability.jaeger_enabled
}

output "jaeger_release_name" {
  description = "Jaeger Helm release name"
  value       = module.observability.jaeger_release_name
}

output "jaeger_release_status" {
  description = "Jaeger Helm release status"
  value       = module.observability.jaeger_release_status
}

output "jaeger_query_endpoint" {
  description = "Jaeger Query UI endpoint"
  value       = module.observability.jaeger_query_endpoint
}

output "jaeger_collector_endpoint" {
  description = "Jaeger Collector gRPC endpoint"
  value       = module.observability.jaeger_collector_endpoint
}

output "tempo_enabled" {
  description = "Tempo enabled"
  value       = module.observability.tempo_enabled
}

output "tempo_release_name" {
  description = "Tempo Helm release name"
  value       = module.observability.tempo_release_name
}

output "tempo_release_status" {
  description = "Tempo Helm release status"
  value       = module.observability.tempo_release_status
}

output "tempo_query_endpoint" {
  description = "Tempo Query API endpoint"
  value       = module.observability.tempo_query_endpoint
}

output "tempo_otlp_grpc_endpoint" {
  description = "Tempo OTLP gRPC endpoint"
  value       = module.observability.tempo_otlp_grpc_endpoint
}

output "grafana_jaeger_datasource_name" {
  description = "Grafana Jaeger datasource name"
  value       = module.observability.grafana_jaeger_datasource_name
}

output "grafana_tempo_datasource_name" {
  description = "Grafana Tempo datasource name"
  value       = module.observability.grafana_tempo_datasource_name
}

output "jaeger_port_forward_command" {
  description = "Command to port-forward to Jaeger"
  value       = module.observability.jaeger_port_forward_command
}

output "tempo_port_forward_command" {
  description = "Command to port-forward to Tempo"
  value       = module.observability.tempo_port_forward_command
}

output "sampling_percentage" {
  description = "Trace sampling percentage"
  value       = module.observability.sampling_percentage
}
