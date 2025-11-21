# Create observability namespace
resource "kubernetes_namespace" "observability" {
  count = var.enable_observability ? 1 : 0

  metadata {
    name = var.observability_namespace
    labels = {
      "app.kubernetes.io/name"       = "observability"
      "app.kubernetes.io/component"  = "observability"
    }
  }
}

# Deploy Jaeger for distributed tracing
resource "helm_release" "jaeger" {
  count = var.enable_observability && var.enable_jaeger ? 1 : 0

  name             = "jaeger"
  repository       = "https://jaegertracing.github.io/helm-charts"
  chart            = "jaeger"
  namespace        = kubernetes_namespace.observability[0].metadata[0].name
  version          = var.jaeger_chart_version
  create_namespace = false

  values = [
    yamlencode({
      replicas = var.jaeger_replicas

      storage = {
        type = var.jaeger_storage_type
      }

      query = {
        enabled = true
      }

      collector = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
        ports = {
          grpc = {
            enabled = true
            port    = var.jaeger_grpc_port
          }
          thrift = {
            compact = {
              enabled = true
              port    = var.jaeger_compact_port
            }
          }
        }
      }

      agent = {
        enabled = true
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      serviceMonitor = {
        enabled = var.enable_observability_monitoring
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Deploy Grafana Tempo for distributed tracing
resource "helm_release" "tempo" {
  count = var.enable_observability && var.enable_tempo ? 1 : 0

  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  namespace        = kubernetes_namespace.observability[0].metadata[0].name
  version          = var.tempo_chart_version
  create_namespace = false

  values = [
    yamlencode({
      replicas = var.tempo_replicas

      tempoQuery = {
        enabled = true
      }

      persistence = {
        enabled = true
        size    = var.tempo_storage_size
        storageClassName = var.tempo_storage_class
      }

      ingester = {
        replicas = var.tempo_replicas
      }

      distributor = {
        replicas = var.tempo_replicas
      }

      querier = {
        replicas = var.tempo_replicas
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }

      service = {
        otlp = {
          protocol = "grpc"
          port     = var.otlp_grpc_port
        }
      }

      serviceMonitor = {
        enabled = var.enable_observability_monitoring
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Deploy OpenTelemetry Collector
resource "helm_release" "otel_collector" {
  count = var.enable_observability && var.enable_otel_collector ? 1 : 0

  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = kubernetes_namespace.observability[0].metadata[0].name
  version          = var.otel_collector_chart_version
  create_namespace = false

  values = [
    yamlencode({
      mode = var.otel_collector_mode

      presets = {
        kubernetesAttributes = {
          enabled = true
        }
        kubeletMetrics = {
          enabled = true
        }
      }

      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:${var.otlp_grpc_port}"
              }
              http = {
                endpoint = "0.0.0.0:${var.otlp_http_port}"
              }
            }
          }
          jaeger = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:${var.jaeger_grpc_port}"
              }
              thrift_compact = {
                endpoint = "0.0.0.0:${var.jaeger_compact_port}"
              }
            }
          }
          prometheus = {
            config = {
              scrape_configs = [
                {
                  job_name = "otel-collector"
                  static_configs = [
                    {
                      targets = ["localhost:${var.metrics_port}"]
                    }
                  ]
                }
              ]
            }
          }
        }

        processors = {
          batch = {
            send_batch_size      = 1024
            timeout              = "10s"
          }
          memory_limiter = {
            check_interval        = "1s"
            limit_mib             = 512
            spike_limit_mib       = 128
          }
          attributes = {
            actions = [
              {
                key    = "deployment.environment"
                value  = "production"
                action = "upsert"
              }
            ]
          }
          probabilistic_sampler = {
            sampling_percentage = var.sampling_percentage
          }
        }

        exporters = {
          otlp = {
            endpoint = var.enable_jaeger ? "jaeger-collector.${kubernetes_namespace.observability[0].metadata[0].name}.svc:${var.jaeger_grpc_port}" : "localhost:4317"
          }
          otlphttp = {
            endpoint = var.enable_tempo ? "http://tempo.${kubernetes_namespace.observability[0].metadata[0].name}.svc:4318" : "http://localhost:4318"
          }
          prometheus = {
            endpoint = "localhost:${var.metrics_port}"
          }
          logging = {
            loglevel = "debug"
          }
        }

        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp", "jaeger"]
              processors = ["memory_limiter", "batch", "attributes", "probabilistic_sampler"]
              exporters  = var.enable_jaeger && var.enable_tempo ? ["otlp", "otlphttp", "logging"] : var.enable_jaeger ? ["otlp", "logging"] : ["otlphttp", "logging"]
            }
            metrics = {
              receivers  = ["prometheus"]
              processors = ["batch"]
              exporters  = ["prometheus"]
            }
          }
        }
      }

      resources = {
        requests = {
          cpu    = var.otel_collector_cpu_request
          memory = var.otel_collector_memory_request
        }
        limits = {
          cpu    = var.otel_collector_cpu_limit
          memory = var.otel_collector_memory_limit
        }
      }

      serviceMonitor = {
        enabled = var.enable_observability_monitoring
      }

      ports = {
        otlp-grpc = {
          enabled = true
          containerPort = var.otlp_grpc_port
          servicePort = var.otlp_grpc_port
          protocol = "TCP"
        }
        otlp-http = {
          enabled = true
          containerPort = var.otlp_http_port
          servicePort = var.otlp_http_port
          protocol = "TCP"
        }
        jaeger-grpc = {
          enabled = true
          containerPort = var.jaeger_grpc_port
          servicePort = var.jaeger_grpc_port
          protocol = "TCP"
        }
        jaeger-compact = {
          enabled = true
          containerPort = var.jaeger_compact_port
          servicePort = var.jaeger_compact_port
          protocol = "UDP"
        }
        prometheus = {
          enabled = true
          containerPort = var.metrics_port
          servicePort = var.metrics_port
          protocol = "TCP"
        }
        healthcheck = {
          enabled = true
          containerPort = var.health_check_port
          servicePort = var.health_check_port
          protocol = "TCP"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.observability]
}

# Create Grafana datasource for Jaeger
resource "kubernetes_config_map" "grafana_datasource_jaeger" {
  count = var.enable_observability && var.enable_jaeger ? 1 : 0

  metadata {
    name      = "grafana-datasource-jaeger"
    namespace = var.grafana_namespace
    labels = {
      "grafana_datasource" = "1"
    }
  }

  data = {
    "jaeger-datasource.yaml" = yamlencode({
      apiVersion = 1
      datasources = [
        {
          name           = "Jaeger"
          type           = "jaeger"
          access         = "proxy"
          url            = "http://jaeger-query.${kubernetes_namespace.observability[0].metadata[0].name}:16686"
          jsonData = {
            nodeGraph = {
              enabled = true
            }
          }
          isDefault = false
        }
      ]
    })
  }

  depends_on = [helm_release.jaeger]
}

# Create Grafana datasource for Tempo
resource "kubernetes_config_map" "grafana_datasource_tempo" {
  count = var.enable_observability && var.enable_tempo ? 1 : 0

  metadata {
    name      = "grafana-datasource-tempo"
    namespace = var.grafana_namespace
    labels = {
      "grafana_datasource" = "1"
    }
  }

  data = {
    "tempo-datasource.yaml" = yamlencode({
      apiVersion = 1
      datasources = [
        {
          name           = "Tempo"
          type           = "tempo"
          access         = "proxy"
          url            = "http://tempo.${kubernetes_namespace.observability[0].metadata[0].name}:3100"
          jsonData = {
            nodeGraph = {
              enabled = true
            }
            lokiSearch = {
              enabled = false
            }
          }
          isDefault = false
        }
      ]
    })
  }

  depends_on = [helm_release.tempo]
}

# Create sample dashboards ConfigMap
resource "kubernetes_config_map" "grafana_dashboard_traces" {
  count = var.enable_observability ? 1 : 0

  metadata {
    name      = "grafana-dashboard-traces"
    namespace = var.grafana_namespace
    labels = {
      "grafana_dashboard" = "1"
    }
  }

  data = {
    "traces-dashboard.json" = jsonencode({
      dashboard = {
        title       = "Distributed Traces Overview"
        description = "Overview of distributed traces from OpenTelemetry"
        uid         = "traces-overview"
        timezone    = "browser"
        panels = [
          {
            title       = "Traces per Service"
            type        = "stat"
            datasource  = "Tempo"
            targets = [
              {
                expr = "sum by (service.name) (rate(tempo_distributor_trace_received_total[5m]))"
              }
            ]
          },
          {
            title       = "P50 Latency"
            type        = "timeseries"
            datasource  = "Tempo"
            targets = [
              {
                expr = "histogram_quantile(0.50, rate(tempo_distributor_trace_duration_seconds_bucket[5m]))"
              }
            ]
          },
          {
            title       = "Error Rate"
            type        = "stat"
            datasource  = "Tempo"
            targets = [
              {
                expr = "sum(rate(tempo_distributor_trace_received_total{status=\"error\"}[5m])) / sum(rate(tempo_distributor_trace_received_total[5m]))"
              }
            ]
          }
        ]
      }
    })
  }
}
