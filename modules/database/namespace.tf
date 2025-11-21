resource "kubernetes_namespace" "database" {
  metadata {
    name = var.database_namespace
    labels = {
      "app.kubernetes.io/component" = "database"
    }
  }
}
