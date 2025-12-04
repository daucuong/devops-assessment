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
  default     = "acme"
}

variable "chart_path" {
  description = "Path to local Helm chart"
  type        = string
  default     = "./helm/acme"
}

# UI Container Image Configuration
variable "image_repository" {
  description = "Docker image repository for UI"
  type        = string
  default     = "acme"
}

variable "image_tag" {
  description = "Docker image tag for UI"
  type        = string
  default     = "latest"
}

# API Container Image Configuration
variable "api_image_repository" {
  description = "Docker image repository for API"
  type        = string
  default     = "acme-api"
}

variable "api_image_tag" {
  description = "Docker image tag for API"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

# UI Deployment Configuration
variable "replicas" {
  description = "Number of UI replicas"
  type        = number
  default     = 2
}

# API Deployment Configuration
variable "api_replicas" {
  description = "Number of API replicas"
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
  description = "Service port (deprecated, use ingress routing instead)"
  type        = number
  default     = 3000
}

# Autoscaling Configuration
variable "autoscaling_enabled" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 2
}

variable "autoscaling_max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 10
}

variable "autoscaling_metrics" {
  description = "Autoscaling metrics configuration"
  type = list(object({
    type = string
    resource = optional(object({
      name = string
      target = object({
        type                 = string
        averageUtilization   = optional(number)
        averageValue         = optional(string)
      })
    }))
  }))
  default = [
    {
      type = "Resource"
      resource = {
        name = "cpu"
        target = {
          type             = "Utilization"
          averageUtilization = 50
        }
      }
    },
    {
      type = "Resource"
      resource = {
        name = "memory"
        target = {
          type             = "Utilization"
          averageUtilization = 70
        }
      }
    }
  ]
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable Ingress"
  type        = bool
  default     = false
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
      host = "www.acme.com"
      paths = [
        {
          path     = "/"
          pathType = "Prefix"
        }
      ]
    },
    {
      host = "api.acme.com"
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
