# Prometheus Deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.app_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus"

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
        }

        volume {
          name = "prometheus-config"

          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }

        volume {
          name = "prometheus-storage"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = var.app_namespace
  }

  data = {
    "prometheus.yml" = <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'api'
    static_configs:
      - targets: ['api-service.acme.svc.cluster.local:8080']
  - job_name: 'ui'
    static_configs:
      - targets: ['ui-service.acme.svc.cluster.local:80']
EOF
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-service"
    namespace = var.app_namespace
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 80
      target_port = 9090
    }

    type = "ClusterIP"
  }
}

# Prometheus Operator for comprehensive monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

resource "kubernetes_service_account" "prometheus_operator" {
  metadata {
    name      = "prometheus-operator"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "prometheus_operator" {
  metadata {
    name = "prometheus-operator"
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "deployments", "daemonsets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets", "services", "serviceaccounts", "pods"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterrolebindings", "clusterroles", "rolebindings", "roles"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus_operator" {
  metadata {
    name = "prometheus-operator"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus_operator.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus_operator.metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

resource "kubernetes_deployment" "prometheus_operator" {
  metadata {
    name      = "prometheus-operator"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "prometheus-operator"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus-operator"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus-operator"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.prometheus_operator.metadata[0].name

        container {
          name  = "operator"
          image = "quay.io/prometheus-operator/prometheus-operator:v0.63.0"

          args = [
            "--kubelet-service=kube-system/kubelet",
            "--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v0.63.0",
          ]

          port {
            container_port = 8080
            name           = "http"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# OpenTelemetry Collector for tracing
resource "kubernetes_namespace" "opentelemetry" {
  metadata {
    name = "opentelemetry"
  }
}

resource "kubernetes_config_map" "otel_config" {
  metadata {
    name      = "otel-collector-config"
    namespace = kubernetes_namespace.opentelemetry.metadata[0].name
  }

  data = {
    "config.yaml" = <<EOF
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
EOF
  }
}

resource "kubernetes_deployment" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.opentelemetry.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "otel-collector"
      }
    }

    template {
      metadata {
        labels = {
          app = "otel-collector"
        }
      }

      spec {
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector:0.74.0"

          args = ["--config=/conf/config.yaml"]

          port {
            container_port = 4317
            name           = "grpc"
          }

          port {
            container_port = 4318
            name           = "http"
          }

          volume_mount {
            name       = "config"
            mount_path = "/conf"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.otel_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.opentelemetry.metadata[0].name
  }

  spec {
    selector = {
      app = "otel-collector"
    }

    port {
      name = "grpc"
      port = 4317
    }

    port {
      name = "http"
      port = 4318
    }
  }
}

# ELK Stack for logging
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "kubernetes_stateful_set" "elasticsearch" {
  metadata {
    name      = "elasticsearch"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    service_name = "elasticsearch"
    replicas     = 1

    selector {
      match_labels = {
        app = "elasticsearch"
      }
    }

    template {
      metadata {
        labels = {
          app = "elasticsearch"
        }
      }

      spec {
        container {
          name  = "elasticsearch"
          image = "docker.elastic.co/elasticsearch/elasticsearch:8.7.0"

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          env {
            name  = "xpack.security.enabled"
            value = "false"
          }

          env {
            name  = "ES_JAVA_OPTS"
            value = "-Xms256m -Xmx256m"
          }

          port {
            container_port = 9200
          }

          volume_mount {
            name       = "data"
            mount_path = "/usr/share/elasticsearch/data"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "1Gi"
            }
          }
        }

        volume {
          name = "data"

          empty_dir {}
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elasticsearch" {
  metadata {
    name      = "elasticsearch"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    selector = {
      app = "elasticsearch"
    }

    port {
      port = 9200
    }
  }
}

resource "kubernetes_deployment" "kibana" {
  metadata {
    name      = "kibana"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kibana"
      }
    }

    template {
      metadata {
        labels = {
          app = "kibana"
        }
      }

      spec {
        container {
          name  = "kibana"
          image = "docker.elastic.co/kibana/kibana:8.7.0"

          port {
            container_port = 5601
          }

          env {
            name  = "ELASTICSEARCH_HOSTS"
            value = "http://elasticsearch:9200"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kibana" {
  metadata {
    name      = "kibana"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    selector = {
      app = "kibana"
    }

    port {
      port = 5601
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "logstash" {
  metadata {
    name      = "logstash"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "logstash"
      }
    }

    template {
      metadata {
        labels = {
          app = "logstash"
        }
      }

      spec {
        container {
          name  = "logstash"
          image = "docker.elastic.co/logstash/logstash:8.7.0"

          port {
            container_port = 5044
          }

          volume_mount {
            name       = "config"
            mount_path = "/usr/share/logstash/pipeline"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.logstash_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "logstash_config" {
  metadata {
    name      = "logstash-config"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  data = {
    "logstash.conf" = <<EOF
input {
  beats {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "kubernetes-%%{+YYYY.MM.dd}"
  }
}
EOF
  }
}

resource "kubernetes_service" "logstash" {
  metadata {
    name      = "logstash"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    selector = {
      app = "logstash"
    }

    port {
      port = 5044
    }
  }
}
