# NGINX Ingress Controller Variables
variable "ingress_namespace" {
  description = "Namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_name" {
  description = "Name of NGINX Ingress Helm release"
  type        = string
  default     = "nginx-ingress"
}

variable "nginx_ingress_repository" {
  description = "Helm repository for NGINX Ingress"
  type        = string
  default     = "https://kubernetes.github.io/ingress-nginx"
}

variable "nginx_ingress_chart" {
  description = "Helm chart for NGINX Ingress"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_version" {
  description = "Version of NGINX Ingress chart"
  type        = string
  default     = "4.10.0"
}

variable "nginx_service_type" {
  description = "Service type for NGINX Ingress"
  type        = string
  default     = "LoadBalancer"
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

# Application Ingress Variables
variable "app_namespace" {
  description = "Namespace where application is deployed"
  type        = string
  default     = "default"
}

variable "app_service_name" {
  description = "Name of the UI application service (deprecated, hardcoded to acme)"
  type        = string
  default     = "acme"
}

variable "app_service_port" {
  description = "Port of the application service (deprecated, uses port name 'http')"
  type        = number
  default     = 3000
}

variable "ingress_name" {
  description = "Name of the ingress resource"
  type        = string
  default     = "app-ingress"
}

# Logging Variables
variable "enable_logging" {
  description = "Enable NGINX access logging"
  type        = bool
  default     = true
}

variable "log_format_main" {
  description = "Main access log format"
  type        = string
  default     = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\" $request_time $upstream_response_time $upstream_addr $upstream_status"
}

variable "log_format_upstream" {
  description = "Upstream log format (detailed request information)"
  type        = string
  default     = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" $request_length $request_time $upstream_addr $upstream_response_time $upstream_status $upstream_cache_status"
}
