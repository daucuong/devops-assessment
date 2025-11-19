output "app_namespace" {
  description = "The namespace for the application"
  value       = kubernetes_namespace.acme.metadata[0].name
}
