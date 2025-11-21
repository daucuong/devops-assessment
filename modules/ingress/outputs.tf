output "nginx_ingress_namespace" {
  description = "NGINX Ingress namespace"
  value       = kubernetes_namespace.ingress_nginx.metadata[0].name
}

output "nginx_ingress_release_name" {
  description = "NGINX Ingress release name"
  value       = helm_release.nginx_ingress.name
}
