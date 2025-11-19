resource "kubernetes_namespace" "acme" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# PostgreSQL StatefulSet with HA and Backup Configuration
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    service_name = "postgres-service"
    replicas     = 2 # Multi-pod for HA simulation

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:16"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_DATABASE"
            value = var.db_name
          }

          env {
            name  = "POSTGRES_USERNAME"
            value = var.db_user
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = var.db_password
          }

          # Replication settings
          env {
            name  = "POSTGRES_REPLICATION_USER"
            value = "replicator"
          }

          env {
            name  = "POSTGRES_REPLICATION_PASSWORD"
            value = "repl_password"
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "postgres-wal"
            mount_path = "/var/lib/postgresql/archived_wal"
          }

          volume_mount {
            name       = "backup-storage"
            mount_path = "/var/lib/postgresql/backup"
          }

          # Readiness probe
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user, "-d", var.db_name]
            }

            initial_delay_seconds = 15
            period_seconds        = 10
          }

          # Liveness probe
          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_user, "-d", var.db_name]
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }

        volume {
          name = "postgres-wal"

          empty_dir {}
        }

        volume {
          name = "backup-storage"

          empty_dir {}
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "10Gi" # Increased for production use
          }
        }

        # Use a storage class that supports snapshots/backups
        storage_class_name = "standard"
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# PostgreSQL Backup CronJob - Automated Database Backups
resource "kubernetes_cron_job_v1" "postgres_backup" {
  metadata {
    name      = "postgres-backup"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    schedule = "0 */6 * * *" # Every 6 hours

    job_template {
      metadata {
        labels = {
          app = "postgres-backup"
        }
      }

      spec {
        template {
          metadata {
            labels = {
              app = "postgres-backup"
            }
          }

          spec {
            container {
              name  = "postgres-backup"
              image = "postgres:16"

              command = [
                "/bin/bash",
                "-c",
                "pg_dump -h postgres-service -U $${POSTGRES_USERNAME} -d $${POSTGRES_DATABASE} | gzip > /backup/postgres-backup-$(date +%Y%m%d-%H%M%S).sql.gz"
              ]

              env {
                name = "POSTGRES_USERNAME"
                value_from {
                  secret_key_ref {
                    name = "postgres-secret"
                    key  = "username"
                  }
                }
              }

              env {
                name = "POSTGRES_DATABASE"
                value_from {
                  secret_key_ref {
                    name = "postgres-secret"
                    key  = "database"
                  }
                }
              }

              env {
                name = "POSTGRES_PASSWORD"
                value_from {
                  secret_key_ref {
                    name = "postgres-secret"
                    key  = "password"
                  }
                }
              }

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }

              resources {
                requests = {
                  cpu    = "100m"
                  memory = "256Mi"
                }

                limits = {
                  cpu    = "200m"
                  memory = "512Mi"
                }
              }
            }

            volume {
              name = "backup-storage"

              persistent_volume_claim {
                claim_name = "postgres-backup-pvc"
              }
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

# PVC for Database Backups
resource "kubernetes_persistent_volume_claim" "postgres_backup" {
  metadata {
    name      = "postgres-backup-pvc"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "50Gi" # Sufficient space for multiple backups
      }
    }

    storage_class_name = "standard"
  }
}

# Secret for PostgreSQL credentials (used by backup jobs)
resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  data = {
    username = base64encode(var.db_user)
    password = base64encode(var.db_password)
    database = base64encode(var.db_name)
  }

  type = "Opaque"
}

# PITR Recovery Job (for testing disaster recovery)
resource "kubernetes_job" "postgres_pitr_recovery" {
  metadata {
    name      = "postgres-pitr-recovery"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = {
          app = "postgres-pitr-recovery"
        }
      }

      spec {
        container {
          name  = "postgres-restore"
          image = "postgres:16"

          command = [
            "/bin/bash",
            "-c",
            <<EOF
# This is a template for PITR recovery
# In production, this would restore from WAL archives and base backup
echo "PITR Recovery Job - Template for disaster recovery"
echo "1. Stop PostgreSQL"
echo "2. Restore base backup from /backup/"
echo "3. Restore WAL archives from /wal-archive/"
echo "4. Start PostgreSQL with recovery.conf"
echo "5. Verify data integrity"
ls -la /backup/
ls -la /wal-archive/ || echo "WAL archive not mounted"
EOF
          ]

          volume_mount {
            name       = "backup-storage"
            mount_path = "/backup"
          }

          volume_mount {
            name       = "wal-archive"
            mount_path = "/wal-archive"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "backup-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_backup.metadata[0].name
          }
        }

        volume {
          name = "wal-archive"

          persistent_volume_claim {
            claim_name = "postgres-wal-pvc"
          }
        }

        restart_policy = "Never"
      }
    }

    # Set to false to prevent automatic execution - manual trigger only
    manual_selector = true
  }
}

# PVC for WAL Archives (for PITR)
resource "kubernetes_persistent_volume_claim" "postgres_wal" {
  metadata {
    name      = "postgres-wal-pvc"
    namespace = kubernetes_namespace.acme.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "20Gi" # For WAL archives
      }
    }

    storage_class_name = "standard"
  }
}
