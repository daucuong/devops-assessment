variable "create_namespace" {
  description = "Create the namespace"
  type        = bool
  default     = true
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "application"
}

# Helm Release Configuration
variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "echo-server"
}

variable "repository" {
  description = "Helm repository URL"
  type        = string
  default     = "https://ealenn.github.io/charts"
}

variable "chart" {
  description = "Helm chart name"
  type        = string
  default     = "echo-server"
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = ""
}

# Container Image Configuration
variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "ealen/echo-server"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

# Deployment Configuration
variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

# Service Configuration
variable "service_type" {
  description = "Service type"
  type        = string
  default     = "ClusterIP"
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 3000
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable Ingress"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "ingress_hosts" {
  description = "Ingress hosts configuration"
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

variable "ingress_tls" {
  description = "Ingress TLS configuration"
  type = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default = []
}

# Resource Configuration
variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

# Environment Variables
variable "environment_variables" {
  description = "Environment variables for the application"
  type        = list(object({
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
