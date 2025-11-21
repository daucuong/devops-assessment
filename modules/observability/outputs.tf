# Observability Module Outputs

output "observability_namespace" {
  description = "Observability namespace"
  value       = var.enable_observability ? kubernetes_namespace.observability[0].metadata[0].name : ""
}

# OpenTelemetry Collector Outputs
output "otel_collector_enabled" {
  description = "OpenTelemetry Collector enabled"
  value       = var.enable_observability && var.enable_otel_collector
}

output "otel_collector_release_name" {
  description = "OpenTelemetry Collector Helm release name"
  value       = var.enable_observability && var.enable_otel_collector ? helm_release.otel_collector[0].metadata[0].name : ""
}

output "otel_collector_mode" {
  description = "OpenTelemetry Collector mode"
  value       = var.otel_collector_mode
}

output "otel_collector_otlp_grpc_endpoint" {
  description = "OpenTelemetry Collector OTLP gRPC endpoint"
  value       = var.enable_observability && var.enable_otel_collector ? "opentelemetry-collector.${kubernetes_namespace.observability[0].metadata[0].name}.svc:${var.otlp_grpc_port}" : ""
}

output "otel_collector_otlp_http_endpoint" {
  description = "OpenTelemetry Collector OTLP HTTP endpoint"
  value       = var.enable_observability && var.enable_otel_collector ? "http://opentelemetry-collector.${kubernetes_namespace.observability[0].metadata[0].name}.svc:${var.otlp_http_port}" : ""
}

output "otel_collector_jaeger_grpc_endpoint" {
  description = "OpenTelemetry Collector Jaeger gRPC endpoint"
  value       = var.enable_observability && var.enable_otel_collector ? "opentelemetry-collector.${kubernetes_namespace.observability[0].metadata[0].name}.svc:${var.jaeger_grpc_port}" : ""
}

output "otel_collector_metrics_port" {
  description = "OpenTelemetry Collector Prometheus metrics port"
  value       = var.metrics_port
}

# Jaeger Outputs
output "jaeger_enabled" {
  description = "Jaeger enabled"
  value       = var.enable_observability && var.enable_jaeger
}

output "jaeger_release_name" {
  description = "Jaeger Helm release name"
  value       = var.enable_observability && var.enable_jaeger ? helm_release.jaeger[0].metadata[0].name : ""
}

output "jaeger_release_status" {
  description = "Jaeger Helm release status"
  value       = var.enable_observability && var.enable_jaeger ? helm_release.jaeger[0].status : ""
}

output "jaeger_query_endpoint" {
  description = "Jaeger Query UI endpoint"
  value       = var.enable_observability && var.enable_jaeger ? "http://jaeger-query.${kubernetes_namespace.observability[0].metadata[0].name}:16686" : ""
}

output "jaeger_collector_endpoint" {
  description = "Jaeger Collector gRPC endpoint"
  value       = var.enable_observability && var.enable_jaeger ? "jaeger-collector.${kubernetes_namespace.observability[0].metadata[0].name}.svc:${var.jaeger_grpc_port}" : ""
}

output "jaeger_grpc_port" {
  description = "Jaeger gRPC port"
  value       = var.jaeger_grpc_port
}

output "jaeger_compact_port" {
  description = "Jaeger compact Thrift port"
  value       = var.jaeger_compact_port
}

output "jaeger_storage_type" {
  description = "Jaeger storage type"
  value       = var.jaeger_storage_type
}

# Tempo Outputs
output "tempo_enabled" {
  description = "Tempo enabled"
  value       = var.enable_observability && var.enable_tempo
}

output "tempo_release_name" {
  description = "Tempo Helm release name"
  value       = var.enable_observability && var.enable_tempo ? helm_release.tempo[0].metadata[0].name : ""
}

output "tempo_release_status" {
  description = "Tempo Helm release status"
  value       = var.enable_observability && var.enable_tempo ? helm_release.tempo[0].status : ""
}

output "tempo_query_endpoint" {
  description = "Tempo Query UI endpoint"
  value       = var.enable_observability && var.enable_tempo ? "http://tempo.${kubernetes_namespace.observability[0].metadata[0].name}:3100" : ""
}

output "tempo_otlp_grpc_endpoint" {
  description = "Tempo OTLP gRPC endpoint"
  value       = var.enable_observability && var.enable_tempo ? "http://tempo.${kubernetes_namespace.observability[0].metadata[0].name}:${var.otlp_grpc_port}" : ""
}

output "tempo_storage_size" {
  description = "Tempo storage size"
  value       = var.tempo_storage_size
}

# Grafana Integration
output "grafana_jaeger_datasource_name" {
  description = "Grafana Jaeger datasource name"
  value       = "Jaeger"
}

output "grafana_tempo_datasource_name" {
  description = "Grafana Tempo datasource name"
  value       = "Tempo"
}

# Access Commands
output "jaeger_port_forward_command" {
  description = "Command to port-forward to Jaeger"
  value       = var.enable_observability && var.enable_jaeger ? "kubectl port-forward -n ${kubernetes_namespace.observability[0].metadata[0].name} svc/jaeger-query 16686:16686" : ""
}

output "tempo_port_forward_command" {
  description = "Command to port-forward to Tempo"
  value       = var.enable_observability && var.enable_tempo ? "kubectl port-forward -n ${kubernetes_namespace.observability[0].metadata[0].name} svc/tempo 3100:3100" : ""
}

output "otel_collector_port_forward_command" {
  description = "Command to port-forward to OpenTelemetry Collector"
  value       = var.enable_observability && var.enable_otel_collector ? "kubectl port-forward -n ${kubernetes_namespace.observability[0].metadata[0].name} svc/opentelemetry-collector ${var.otlp_grpc_port}:${var.otlp_grpc_port}" : ""
}

# Configuration
output "sampling_percentage" {
  description = "Trace sampling percentage"
  value       = var.sampling_percentage
}

output "otlp_grpc_port" {
  description = "OTLP gRPC port"
  value       = var.otlp_grpc_port
}

output "otlp_http_port" {
  description = "OTLP HTTP port"
  value       = var.otlp_http_port
}

# Verification Commands
output "check_otel_pods_command" {
  description = "Command to check OpenTelemetry Collector pods"
  value       = var.enable_observability ? "kubectl get pods -n ${kubernetes_namespace.observability[0].metadata[0].name} -l app.kubernetes.io/name=opentelemetry-collector" : ""
}

output "check_jaeger_pods_command" {
  description = "Command to check Jaeger pods"
  value       = var.enable_observability && var.enable_jaeger ? "kubectl get pods -n ${kubernetes_namespace.observability[0].metadata[0].name} -l app.kubernetes.io/name=jaeger" : ""
}

output "check_tempo_pods_command" {
  description = "Command to check Tempo pods"
  value       = var.enable_observability && var.enable_tempo ? "kubectl get pods -n ${kubernetes_namespace.observability[0].metadata[0].name} -l app.kubernetes.io/name=tempo" : ""
}

output "check_all_observability_pods_command" {
  description = "Command to check all observability pods"
  value       = var.enable_observability ? "kubectl get pods -n ${kubernetes_namespace.observability[0].metadata[0].name}" : ""
}
