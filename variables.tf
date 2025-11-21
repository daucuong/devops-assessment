variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "docker-desktop"
}

# Helm - Ingress Controller
variable "ingress_namespace" {
  description = "Namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_service_type" {
  description = "Service type for NGINX Ingress"
  type        = string
  default     = "NodePort"
}

variable "nginx_cpu_request" {
  description = "CPU request for NGINX controller"
  type        = string
  default     = "100m"
}

variable "nginx_memory_request" {
  description = "Memory request for NGINX controller"
  type        = string
  default     = "90Mi"
}

variable "nginx_cpu_limit" {
  description = "CPU limit for NGINX controller"
  type        = string
  default     = "500m"
}

variable "nginx_memory_limit" {
  description = "Memory limit for NGINX controller"
  type        = string
  default     = "512Mi"
}

# Helm - Monitoring
variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring"
  type        = string
  default     = "monitoring"
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

# Helm - Cert-Manager
variable "enable_cert_manager" {
  description = "Enable cert-manager for SSL/TLS"
  type        = bool
  default     = false
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

# Helm - External Secrets
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator for secret management"
  type        = bool
  default     = false
}

# Helm - Istio
variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}

# Database Module Variables
variable "database_namespace" {
  description = "Namespace for database components"
  type        = string
  default     = "database"
}

variable "enable_database" {
  description = "Enable PostgreSQL database deployment"
  type        = bool
  default     = false
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16-latest"
}

variable "postgres_instances" {
  description = "Number of PostgreSQL instances (HA cluster)"
  type        = number
  default     = 3
}

variable "postgres_storage_class" {
  description = "Storage class for PostgreSQL persistent volumes"
  type        = string
  default     = "standard"
}

variable "postgres_password" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
  default     = "postgres123!"
}

variable "rto_minutes" {
  description = "Recovery Time Objective in minutes"
  type        = number
  default     = 5
}

variable "rpo_minutes" {
  description = "Recovery Point Objective in minutes"
  type        = number
  default     = 1
}

# Application Module Variables (Echo Server)
variable "app_create_namespace" {
  description = "Create namespace for echo-server"
  type        = bool
  default     = true
}

variable "app_namespace_name" {
  description = "Namespace name for echo-server"
  type        = string
  default     = "application"
}

variable "app_release_name" {
  description = "Helm release name for echo-server"
  type        = string
  default     = "echo-server"
}

variable "app_repository" {
  description = "Helm repository URL for echo-server"
  type        = string
  default     = "https://ealenn.github.io/charts"
}

variable "app_chart" {
  description = "Helm chart name for echo-server"
  type        = string
  default     = "echo-server"
}

variable "app_chart_version" {
  description = "Helm chart version for echo-server"
  type        = string
  default     = ""
}

variable "app_image_repository" {
  description = "Docker image repository for echo-server"
  type        = string
  default     = "ealen/echo-server"
}

variable "app_image_tag" {
  description = "Docker image tag for echo-server"
  type        = string
  default     = "latest"
}

variable "app_image_pull_policy" {
  description = "Image pull policy for echo-server"
  type        = string
  default     = "IfNotPresent"
}

variable "app_replicas_count" {
  description = "Number of echo-server replicas"
  type        = number
  default     = 2
}

variable "app_service_type" {
  description = "Echo-server service type"
  type        = string
  default     = "ClusterIP"
}

variable "app_service_port" {
  description = "Echo-server service port"
  type        = number
  default     = 3000
}

variable "app_enable_ingress" {
  description = "Enable Ingress for echo-server"
  type        = bool
  default     = true
}

variable "app_ingress_class" {
  description = "Ingress class for echo-server"
  type        = string
  default     = "nginx"
}

variable "app_ingress_annotations" {
  description = "Ingress annotations for echo-server"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "app_ingress_hosts" {
  description = "Ingress hosts for echo-server"
  type = list(object({
    host  = string
    paths = optional(list(object({
      path     = string
      pathType = string
    })), [])
  }))
  default = [
    {
      host = "echo-server.local"
      paths = [
        {
          path     = "/"
          pathType = "Prefix"
        }
      ]
    }
  ]
}

variable "app_ingress_tls" {
  description = "Ingress TLS configuration for echo-server"
  type = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default = []
}

variable "app_cpu_request" {
  description = "CPU request for echo-server"
  type        = string
  default     = "100m"
}

variable "app_cpu_limit" {
  description = "CPU limit for echo-server"
  type        = string
  default     = "500m"
}

variable "app_memory_request" {
  description = "Memory request for echo-server"
  type        = string
  default     = "128Mi"
}

variable "app_memory_limit" {
  description = "Memory limit for echo-server"
  type        = string
  default     = "512Mi"
}

variable "app_environment_variables" {
  description = "Environment variables for echo-server"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "PORT"
      value = "3000"
    }
  ]
}

# CI/CD Module Variables (ArgoCD)
variable "enable_cicd" {
  description = "Enable CI/CD module (ArgoCD)"
  type        = bool
  default     = true
}

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

variable "argocd_sync_policy" {
  description = "ArgoCD sync policy (automated or manual)"
  type        = string
  default     = "automated"
}

variable "argocd_auto_prune" {
  description = "Automatically prune resources not in Git"
  type        = bool
  default     = true
}

variable "argocd_self_heal" {
  description = "Enable self-healing for ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  default     = ""
  sensitive   = true
}

# Observability Module Variables (OpenTelemetry, Jaeger, Tempo)
variable "enable_observability" {
  description = "Enable observability module"
  type        = bool
  default     = true
}

variable "observability_namespace" {
  description = "Kubernetes namespace for observability components"
  type        = string
  default     = "observability"
}

variable "enable_otel_collector" {
  description = "Enable OpenTelemetry Collector"
  type        = bool
  default     = true
}

variable "otel_collector_mode" {
  description = "OpenTelemetry Collector deployment mode"
  type        = string
  default     = "daemonset"
}

variable "otel_collector_replicas" {
  description = "Number of OpenTelemetry Collector replicas"
  type        = number
  default     = 1
}

variable "otel_collector_chart_version" {
  description = "OpenTelemetry Collector Helm chart version"
  type        = string
  default     = "0.88.0"
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
  description = "Jaeger storage type"
  type        = string
  default     = "memory"
}

variable "jaeger_replicas" {
  description = "Number of Jaeger replicas"
  type        = number
  default     = 1
}

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

variable "sampling_percentage" {
  description = "Trace sampling percentage"
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

variable "enable_observability_monitoring" {
  description = "Enable Prometheus monitoring for observability"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Metrics server port"
  type        = number
  default     = 8888
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 13133
}
