# Database Module Variables
variable "database_namespace" {
  description = "Namespace for database components"
  type        = string
  default     = "database"
}

variable "enable_database" {
  description = "Enable database deployment"
  type        = bool
  default     = true
}

# CloudNative PG Operator
variable "cnpg_repository" {
  description = "CloudNative PG Helm repository"
  type        = string
  default     = "https://cloudnative-pg.github.io/charts"
}

variable "cnpg_chart" {
  description = "CloudNative PG Helm chart"
  type        = string
  default     = "cloudnative-pg"
}

variable "cnpg_version" {
  description = "CloudNative PG chart version"
  type        = string
  default     = "0.21.0"
}

# PostgreSQL Configuration
variable "postgres_cluster_name" {
  description = "PostgreSQL cluster name"
  type        = string
  default     = "postgres-ha"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "postgres_image_registry" {
  description = "PostgreSQL image registry"
  type        = string
  default     = "ghcr.io/cloudnative-pg"
}

variable "postgres_image_name" {
  description = "PostgreSQL image name"
  type        = string
  default     = "postgresql"
}

variable "postgres_instances" {
  description = "Number of PostgreSQL instances (HA cluster)"
  type        = number
  default     = 3
}

variable "postgres_storage_size" {
  description = "Storage size per instance"
  type        = string
  default     = "10Gi"
}

variable "postgres_storage_class" {
  description = "Storage class for PersistentVolumes"
  type        = string
  default     = "backup-storage"
}

variable "postgres_memory_request" {
  description = "Memory request per PostgreSQL pod"
  type        = string
  default     = "512Mi"
}

variable "postgres_cpu_request" {
  description = "CPU request per PostgreSQL pod"
  type        = string
  default     = "250m"
}

variable "postgres_memory_limit" {
  description = "Memory limit per PostgreSQL pod"
  type        = string
  default     = "2Gi"
}

variable "postgres_cpu_limit" {
  description = "CPU limit per PostgreSQL pod"
  type        = string
  default     = "2"
}

variable "postgres_database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "postgres_user" {
  description = "PostgreSQL superuser"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
  default     = "changeme"
}

variable "postgres_service_name" {
  description = "Kubernetes service name for PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "postgres_slot_prefix" {
  description = "Replication slot prefix"
  type        = string
  default     = "postgres"
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = string
  default     = "30d"
}

variable "backup_volume_size" {
  description = "Size of backup storage volume"
  type        = string
  default     = "20Gi"
}

variable "snapshot_class_name" {
  description = "VolumeSnapshotClass name for backups"
  type        = string
  default     = "csi-hostpath-snapclass"
}

# DR/Resilience Expectations
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

variable "enable_volume_snapshots" {
  description = "Enable volume snapshots for backup protection"
  type        = bool
  default     = true
}
