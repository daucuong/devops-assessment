# Observability Module Variables

variable "enable_observability" {
  description = "Enable observability module (OpenTelemetry, Jaeger, Tempo, Grafana)"
  type        = bool
  default     = true
}

# Namespace Variables
variable "observability_namespace" {
  description = "Kubernetes namespace for observability components"
  type        = string
  default     = "observability"
}

# OpenTelemetry Collector Variables
variable "enable_otel_collector" {
  description = "Enable OpenTelemetry Collector"
  type        = bool
  default     = true
}

variable "otel_collector_chart_version" {
  description = "OpenTelemetry Collector Helm chart version"
  type        = string
  default     = "0.88.0"
}

variable "otel_collector_mode" {
  description = "OpenTelemetry Collector deployment mode (daemonset, sidecar, or statefulset)"
  type        = string
  default     = "daemonset"
}

variable "otel_collector_replicas" {
  description = "Number of OpenTelemetry Collector replicas (for statefulset mode)"
  type        = number
  default     = 1
}

variable "otel_collector_cpu_request" {
  description = "CPU request for OpenTelemetry Collector"
  type        = string
  default     = "100m"
}

variable "otel_collector_cpu_limit" {
  description = "CPU limit for OpenTelemetry Collector"
  type        = string
  default     = "500m"
}

variable "otel_collector_memory_request" {
  description = "Memory request for OpenTelemetry Collector"
  type        = string
  default     = "128Mi"
}

variable "otel_collector_memory_limit" {
  description = "Memory limit for OpenTelemetry Collector"
  type        = string
  default     = "512Mi"
}

# Jaeger Variables
variable "enable_jaeger" {
  description = "Enable Jaeger for distributed tracing"
  type        = bool
  default     = true
}

variable "jaeger_chart_version" {
  description = "Jaeger Helm chart version"
  type        = string
  default     = "0.71.1"
}

variable "jaeger_storage_type" {
  description = "Jaeger storage type (memory, elasticsearch, badger)"
  type        = string
  default     = "memory"
}

variable "jaeger_replicas" {
  description = "Number of Jaeger replicas"
  type        = number
  default     = 1
}

# Tempo Variables
variable "enable_tempo" {
  description = "Enable Grafana Tempo for distributed tracing"
  type        = bool
  default     = true
}

variable "tempo_chart_version" {
  description = "Tempo Helm chart version"
  type        = string
  default     = "1.6.1"
}

variable "tempo_storage_class" {
  description = "Storage class for Tempo persistent volume"
  type        = string
  default     = "standard"
}

variable "tempo_storage_size" {
  description = "Storage size for Tempo"
  type        = string
  default     = "10Gi"
}

variable "tempo_replicas" {
  description = "Number of Tempo replicas"
  type        = number
  default     = 1
}

# Grafana Datasources
variable "grafana_namespace" {
  description = "Grafana namespace (for datasources)"
  type        = string
  default     = "monitoring"
}

# Sampling Configuration
variable "sampling_percentage" {
  description = "Trace sampling percentage (0-100)"
  type        = number
  default     = 10
}

variable "otlp_grpc_port" {
  description = "OTLP gRPC receiver port"
  type        = number
  default     = 4317
}

variable "otlp_http_port" {
  description = "OTLP HTTP receiver port"
  type        = number
  default     = 4318
}

variable "jaeger_grpc_port" {
  description = "Jaeger gRPC receiver port"
  type        = number
  default     = 14250
}

variable "jaeger_compact_port" {
  description = "Jaeger compact Thrift receiver port"
  type        = number
  default     = 6831
}

# Monitoring
variable "enable_observability_monitoring" {
  description = "Enable Prometheus monitoring for observability components"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Metrics server port for Prometheus scraping"
  type        = number
  default     = 8888
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 13133
}
