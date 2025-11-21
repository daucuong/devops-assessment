# Security Module Variables
variable "security_namespace" {
  description = "Base namespace for security components"
  type        = string
  default     = "security"
}

# Cert-Manager Variables
variable "enable_cert_manager" {
  description = "Enable cert-manager for SSL/TLS"
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_name" {
  description = "Name of Cert-Manager Helm release"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_repository" {
  description = "Helm repository for Cert-Manager"
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cert_manager_chart" {
  description = "Helm chart for Cert-Manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_version" {
  description = "Version of Cert-Manager chart"
  type        = string
  default     = "v1.13.2"
}

# External Secrets Variables
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator for secret management"
  type        = bool
  default     = true
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_name" {
  description = "Name of External Secrets Operator Helm release"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_repository" {
  description = "Helm repository for External Secrets Operator"
  type        = string
  default     = "https://charts.external-secrets.io"
}

variable "external_secrets_chart" {
  description = "Helm chart for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_version" {
  description = "Version of External Secrets Operator chart"
  type        = string
  default     = "0.9.9"
}

# Istio Variables
variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}

variable "istio_namespace" {
  description = "Namespace for Istio"
  type        = string
  default     = "istio-system"
}

variable "istio_name" {
  description = "Name of Istio Helm release"
  type        = string
  default     = "istio"
}

variable "istio_service_account_name" {
  description = "Name of Istio service account"
  type        = string
  default     = "istiod"
}

variable "istio_repository" {
  description = "Helm repository for Istio"
  type        = string
  default     = "https://istio-release.storage.googleapis.com/charts"
}

variable "istio_chart" {
  description = "Helm chart for Istio"
  type        = string
  default     = "istiod"
}

variable "istio_version" {
  description = "Version of Istio chart"
  type        = string
  default     = "1.19.3"
}

# Network Policy Variables
variable "app_namespace_name" {
  description = "Application namespace for network policies"
  type        = string
  default     = "application"
}

variable "database_namespace" {
  description = "Database namespace for network policies"
  type        = string
  default     = "database"
}

variable "monitoring_namespace" {
  description = "Monitoring namespace for network policies"
  type        = string
  default     = "monitoring"
}

variable "ingress_namespace" {
  description = "Ingress controller namespace for network policies"
  type        = string
  default     = "ingress-nginx"
}

variable "enable_monitoring" {
  description = "Enable monitoring for network policies"
  type        = bool
  default     = true
}
