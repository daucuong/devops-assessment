output "database_namespace" {
  description = "Database namespace"
  value       = kubernetes_namespace.database.metadata[0].name
}

output "postgres_cluster_name" {
  description = "PostgreSQL cluster name"
  value       = var.postgres_cluster_name
}

output "postgres_service_name" {
  description = "PostgreSQL service name"
  value       = var.enable_database ? kubernetes_service.postgres[0].metadata[0].name : null
}

output "postgres_service_fqdn" {
  description = "PostgreSQL service FQDN"
  value       = var.enable_database ? "${kubernetes_service.postgres[0].metadata[0].name}.${kubernetes_namespace.database.metadata[0].name}.svc.cluster.local" : null
}

output "postgres_readonly_service_name" {
  description = "PostgreSQL readonly service name"
  value       = var.enable_database ? kubernetes_service.postgres_readonly[0].metadata[0].name : null
}

output "postgres_instances" {
  description = "Number of PostgreSQL instances"
  value       = var.postgres_instances
}

output "backup_retention_days" {
  description = "Backup retention period"
  value       = var.backup_retention_days
}

output "rto_minutes" {
  description = "Recovery Time Objective (minutes)"
  value       = var.rto_minutes
}

output "rpo_minutes" {
  description = "Recovery Point Objective (minutes)"
  value       = var.rpo_minutes
}

output "dr_strategy" {
  description = "DR strategy summary"
  value = {
    backup_type          = "Continuous WAL archiving to S3"
    replication_mode     = "Synchronous (remote_apply)"
    ha_instances         = var.postgres_instances
    pitr_enabled         = true
    volume_snapshots     = var.enable_volume_snapshots
    pod_disruption_budget = "Minimum 2 replicas available"
    recovery_targets     = "PITR up to ${var.backup_retention_days}"
  }
}

output "cnpg_operator_chart_version" {
  description = "CloudNative PG operator chart version"
  value       = var.enable_database ? var.cnpg_version : null
}
