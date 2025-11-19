# Velero for backups and DR
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

resource "helm_release" "velero" {
  name       = "velero"
  namespace  = kubernetes_namespace.velero.metadata[0].name
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "5.0.0"
  values = [
    <<EOF
    configuration:
      backupStorageLocation:
        provider: local
        name: default
        bucket: velero-local
        config:
          localPath: /var/velero/backups
      volumeSnapshotLocation:
        provider: local
        name: default
        config:
          localPath: /var/velero/backups
    snapshotsEnabled: true
    credentials:
      useSecret: false
    resources:
      requests:
        cpu: 500m
        memory: 128Mi
    EOF
  ]
}

# Scheduled Backup for Database and Application
resource "helm_release" "velero_scheduled_backup" {
  name             = "velero-scheduled-backup"
  chart            = "${path.module}/charts/velero-scheduled-backup"
  namespace        = kubernetes_namespace.velero.metadata[0].name
  create_namespace = false

  values = [
    <<EOF
    schedules:
      - name: daily-database-backup
        schedule: "0 2 * * *"
        template:
          includedNamespaces:
            - acme
          includedResources:
            - persistentvolumeclaims
            - persistentvolumes
          labelSelector:
            matchLabels:
              app: postgres
          storageLocation: default
          ttl: 720h0m0s
          volumeSnapshotLocations:
            - default
    EOF
  ]

  depends_on = [helm_release.velero]
}

# Backup for Application Configuration
resource "helm_release" "velero_app_config_backup" {
  name             = "velero-app-config-backup"
  chart            = "${path.module}/charts/velero-app-config-backup"
  namespace        = kubernetes_namespace.velero.metadata[0].name
  create_namespace = false

  values = [
    <<EOF
    backups:
      - name: app-config-backup
        includedNamespaces:
          - acme
        includedResources:
          - configmaps
          - secrets
          - deployments
          - services
          - ingresses
        excludedResources:
          - pods
          - events
          - replicasets
        storageLocation: default
        ttl: 168h0m0s
    EOF
  ]

  depends_on = [helm_release.velero]
}
