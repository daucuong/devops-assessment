terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}

module "ingress" {
  source = "./modules/ingress"

  ingress_namespace = var.ingress_namespace

  nginx_service_type     = var.nginx_service_type
  nginx_cpu_request      = var.nginx_cpu_request
  nginx_memory_request   = var.nginx_memory_request
  nginx_cpu_limit        = var.nginx_cpu_limit
  nginx_memory_limit     = var.nginx_memory_limit
}

module "security" {
  source = "./modules/security"

  enable_cert_manager     = var.enable_cert_manager
  cert_manager_namespace  = var.cert_manager_namespace
  enable_external_secrets = var.enable_external_secrets
  enable_istio            = var.enable_istio
}

module "monitoring" {
  source = "./modules/monitoring"

  enable_monitoring    = var.enable_monitoring
  monitoring_namespace = var.monitoring_namespace
  grafana_password     = var.grafana_password
}

module "database" {
  source = "./modules/database"

  database_namespace      = var.database_namespace
  enable_database         = var.enable_database
  postgres_version        = var.postgres_version
  postgres_instances      = var.postgres_instances
  postgres_storage_class  = var.postgres_storage_class
  postgres_password       = var.postgres_password
  rto_minutes             = var.rto_minutes
  rpo_minutes             = var.rpo_minutes
}

module "application" {
  source = "./modules/application"

  create_namespace = var.app_create_namespace
  app_namespace    = var.app_namespace_name

  release_name    = var.app_release_name
  repository      = var.app_repository
  chart           = var.app_chart
  chart_version   = var.app_chart_version

  image_repository   = var.app_image_repository
  image_tag          = var.app_image_tag
  image_pull_policy  = var.app_image_pull_policy

  replicas = var.app_replicas_count

  service_type = var.app_service_type
  service_port = var.app_service_port

  enable_ingress      = var.app_enable_ingress
  ingress_class       = var.app_ingress_class
  ingress_annotations = var.app_ingress_annotations
  ingress_hosts       = var.app_ingress_hosts
  ingress_tls         = var.app_ingress_tls

  cpu_request    = var.app_cpu_request
  cpu_limit      = var.app_cpu_limit
  memory_request = var.app_memory_request
  memory_limit   = var.app_memory_limit

  environment_variables = var.app_environment_variables
}

module "cicd" {
  source = "./modules/cicd"

  enable_cicd                = var.enable_cicd
  argocd_namespace           = var.argocd_namespace
  argocd_release_name        = var.argocd_release_name
  argocd_repository          = var.argocd_repository
  argocd_chart               = var.argocd_chart
  argocd_chart_version       = var.argocd_chart_version
  
  git_repository_url         = var.git_repository_url
  git_repository_branch      = var.git_repository_branch
  git_repository_path        = var.git_repository_path
  git_repository_username    = var.git_repository_username
  git_repository_password    = var.git_repository_password
  
  app_namespace_name         = var.app_namespace_name
  
  argocd_sync_policy         = var.argocd_sync_policy
  argocd_auto_prune          = var.argocd_auto_prune
  argocd_self_heal           = var.argocd_self_heal
  argocd_admin_password      = var.argocd_admin_password
}

module "observability" {
  source = "./modules/observability"

  enable_observability              = var.enable_observability
  observability_namespace           = var.observability_namespace
  
  enable_otel_collector             = var.enable_otel_collector
  otel_collector_mode               = var.otel_collector_mode
  otel_collector_replicas           = var.otel_collector_replicas
  otel_collector_chart_version      = var.otel_collector_chart_version
  otel_collector_cpu_request        = var.otel_collector_cpu_request
  otel_collector_cpu_limit          = var.otel_collector_cpu_limit
  otel_collector_memory_request     = var.otel_collector_memory_request
  otel_collector_memory_limit       = var.otel_collector_memory_limit
  
  enable_jaeger                     = var.enable_jaeger
  jaeger_chart_version              = var.jaeger_chart_version
  jaeger_storage_type               = var.jaeger_storage_type
  jaeger_replicas                   = var.jaeger_replicas
  
  enable_tempo                      = var.enable_tempo
  tempo_chart_version               = var.tempo_chart_version
  tempo_storage_class               = var.tempo_storage_class
  tempo_storage_size                = var.tempo_storage_size
  tempo_replicas                    = var.tempo_replicas
  
  grafana_namespace                 = var.monitoring_namespace
  
  sampling_percentage               = var.sampling_percentage
  otlp_grpc_port                    = var.otlp_grpc_port
  otlp_http_port                    = var.otlp_http_port
  jaeger_grpc_port                  = var.jaeger_grpc_port
  jaeger_compact_port               = var.jaeger_compact_port
  
  enable_observability_monitoring   = var.enable_observability_monitoring
  metrics_port                      = var.metrics_port
  health_check_port                 = var.health_check_port
}
