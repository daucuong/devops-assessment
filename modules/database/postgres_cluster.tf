# ConfigMap for backup scripts
resource "kubernetes_config_map" "backup_scripts" {
  count = var.enable_database ? 1 : 0
  metadata {
    name      = "postgres-backup-scripts"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  data = {
    "backup-policy.sh" = file("${path.module}/scripts/backup-policy.sh")
  }

  depends_on = [
    helm_release.cnpg_operator
  ]
}

# Wait for CNPG CRD to be installed
resource "null_resource" "wait_for_cnpg_crd" {
  count = var.enable_database ? 1 : 0

  provisioner "local-exec" {
    command = "bash -c 'for i in {1..60}; do kubectl get crd clusters.postgresql.cnpg.io 2>/dev/null && exit 0; sleep 1; done; exit 1'"
  }

  depends_on = [
    helm_release.cnpg_operator
  ]
}

# PostgreSQL Cluster with HA configuration
resource "kubernetes_manifest" "postgres_cluster" {
  count = var.enable_database ? 1 : 0

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.postgres_cluster_name
      namespace = kubernetes_namespace.database.metadata[0].name
    }
    spec = {
      # PostgreSQL version
      imageName = "${var.postgres_image_registry}/${var.postgres_image_name}:${var.postgres_version}"

      # Number of instances for HA (odd number recommended: 3 for production)
      instances = var.postgres_instances

      # Storage configuration
      storage = {
        size = var.postgres_storage_size
        storageClass = var.postgres_storage_class
      }

      # Resources
      resources = {
        requests = {
          memory = var.postgres_memory_request
          cpu    = var.postgres_cpu_request
        }
        limits = {
          memory = var.postgres_memory_limit
          cpu    = var.postgres_cpu_limit
        }
      }

      # Bootstrap configuration
      bootstrap = {
        initdb = {
          database = var.postgres_database_name
          owner    = var.postgres_user
          secret = {
            name = kubernetes_secret.postgres_credentials[0].metadata[0].name
          }
        }
      }

      # Backup configuration
      backup = {
        retentionPolicy = var.backup_retention_days
      }

      # Replication slots for HA
      replicationSlots = {
        highAvailability = {
          enabled = true
          slotPrefix = var.postgres_slot_prefix
        }
        updateInterval = 30
      }

      # Primary update strategy
      primaryUpdateStrategy = "unsupervised"
    }
  }

  depends_on = [
    null_resource.wait_for_cnpg_crd,
    kubernetes_secret.postgres_credentials
  ]
}

# PostgreSQL credentials secret
resource "kubernetes_secret" "postgres_credentials" {
  count = var.enable_database ? 1 : 0

  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = base64encode(var.postgres_user)
    password = base64encode(var.postgres_password)
  }
}

# Persistent Volume for backups
resource "kubernetes_persistent_volume_claim" "backup_storage" {
  count = 0

  wait_until_bound = true

  metadata {
    name      = "postgres-backup-pvc"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.postgres_storage_class
    

    resources {
      requests = {
        storage = var.backup_volume_size
      }
    }
  }
}

# PodDisruptionBudget for high availability
resource "kubernetes_pod_disruption_budget_v1" "postgres_pdb" {
  count = var.enable_database ? 1 : 0

  metadata {
    name      = "${var.postgres_cluster_name}-pdb"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    min_available = 2
    selector {
      match_labels = {
        "cnpg.io/cluster" = var.postgres_cluster_name
      }
    }
  }
}

# Service for database access
resource "kubernetes_service" "postgres" {
  count = var.enable_database ? 1 : 0

  metadata {
    name      = var.postgres_service_name
    namespace = kubernetes_namespace.database.metadata[0].name
    labels = {
      "cnpg.io/cluster" = var.postgres_cluster_name
    }
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
    selector = {
      "cnpg.io/cluster" = var.postgres_cluster_name
    }
  }
}

# ReadOnly service for read replicas
resource "kubernetes_service" "postgres_readonly" {
  count = var.enable_database ? 1 : 0

  metadata {
    name      = "${var.postgres_service_name}-readonly"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    type = "ClusterIP"
    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
    selector = {
      "cnpg.io/cluster" = var.postgres_cluster_name
      "role"            = "replica"
    }
  }
}
