variable "app_namespace" {
  description = "Namespace for the application"
  type        = string
}

variable "api_image" {
  description = "Docker image for the API"
  type        = string
  default     = "ealen/echo-server:latest"
}

variable "ui_image" {
  description = "Docker image for the UI"
  type        = string
  default     = "ealen/echo-server:latest"
}

variable "api_replicas" {
  description = "Initial number of API replicas"
  type        = number
  default     = 3
}

variable "ui_replicas" {
  description = "Number of UI replicas"
  type        = number
  default     = 2
}

variable "ui_domain" {
  description = "Domain for the UI"
  type        = string
  default     = "www.acme.com"
}

variable "api_domain" {
  description = "Domain for the API"
  type        = string
  default     = "api.acme.com"
}

variable "api_min_replicas" {
  description = "Minimum number of API replicas"
  type        = number
  default     = 3
}

variable "api_max_replicas" {
  description = "Maximum number of API replicas"
  type        = number
  default     = 10
}

variable "api_cpu_target" {
  description = "CPU utilization target for HPA"
  type        = number
  default     = 70
}
