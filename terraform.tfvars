kubeconfig_path     = "~/.kube/config"
kubeconfig_context  = "docker-desktop"

# NGINX Ingress
ingress_namespace    = "ingress-nginx"
nginx_service_type   = "LoadBalancer"
nginx_cpu_request    = "100m"
nginx_memory_request = "90Mi"
nginx_cpu_limit      = "500m"
nginx_memory_limit   = "512Mi"

# Monitoring
enable_monitoring    = true
monitoring_namespace = "monitoring"
grafana_password     = "admin"

# Cert-Manager
enable_cert_manager        = false
cert_manager_namespace     = "cert-manager"

# External Secrets
enable_external_secrets = true

# Istio
enable_istio = false

# Database - PostgreSQL HA Cluster with DR (using Persistent Volumes for backup)
enable_database = true
postgres_version = "16"
postgres_instances = 3
postgres_password = "postgres123!"
postgres_storage_class = "backup-storage"
rto_minutes = 5
rpo_minutes = 1

# ACME Application
app_create_namespace  = true
app_namespace_name    = "application"
app_release_name      = "acme"

app_image_repository  = "acme"
app_image_tag         = "latest"
app_api_image_repository = "acme-api"
app_api_image_tag     = "latest"
app_image_pull_policy = "IfNotPresent"

app_replicas_count    = 2
app_api_replicas_count = 2
app_service_type      = "ClusterIP"
app_service_port      = 3000

app_enable_ingress    = false
app_ingress_class     = "nginx"
app_ingress_annotations = {}
app_ingress_hosts = []
app_ingress_tls = []

app_cpu_request    = "100m"
app_cpu_limit      = "500m"
app_memory_request = "128Mi"
app_memory_limit   = "512Mi"

app_environment_variables = [
  {
    name  = "PORT"
    value = "3000"
  }
]

# Application Autoscaling
app_autoscaling_enabled      = true
app_autoscaling_min_replicas = 2
app_autoscaling_max_replicas = 10

# Ingress Module - Route www.acme.com and api.acme.com to application
app_ingress_service_name    = "acme"
app_ingress_service_port    = 3000
app_ingress_resource_name   = "app-ingress"
