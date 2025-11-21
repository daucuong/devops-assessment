# Observability Module - OpenTelemetry, Jaeger, Tempo & Grafana

This module provides a comprehensive observability stack with distributed tracing, metrics collection, and visualization.

## Architecture

```
Applications
    ↓
OpenTelemetry Collector (OTLP Receiver)
    ├→ Jaeger (gRPC exporter)
    ├→ Tempo (gRPC exporter)
    └→ Prometheus (metrics exporter)
    ↓
Grafana Dashboards
    ├→ Jaeger Datasource
    ├→ Tempo Datasource
    └→ Prometheus Datasource
```

## Components

### 1. OpenTelemetry Collector

**Role**: Receive, process, and export telemetry data

**Features**:
- OTLP gRPC receiver (port 4317)
- OTLP HTTP receiver (port 4318)
- Jaeger gRPC receiver (port 14250)
- Jaeger Thrift compact receiver (port 6831)
- Batch processing for efficiency
- Sampling processor (configurable %)
- Kubernetes attributes auto-detection
- Prometheus metrics export

**Deployment Mode**: DaemonSet (default)

### 2. Jaeger

**Role**: Distributed tracing backend

**Features**:
- Query UI for searching traces
- Trace visualization
- Service dependency graph
- Span analysis
- Storage backends (memory, Elasticsearch, Badger)

**Access**: 
- Query UI: http://jaeger-query:16686
- Collector gRPC: jaeger-collector:14250
- Thrift: jaeger:6831

### 3. Grafana Tempo

**Role**: Scalable distributed tracing backend

**Features**:
- Cost-effective trace storage
- Prometheus-compatible
- Multi-tenant support
- Trace search and visualization
- Integration with Loki for log correlation

**Access**:
- API: http://tempo:3100
- OTLP gRPC: tempo:4317

### 4. Grafana Integration

**Datasources Configured**:
- Jaeger (for trace search)
- Tempo (for trace search)
- Prometheus (for metrics)
- Loki (if enabled)

**Dashboards**:
- Distributed Traces Overview
- Service Latency Analysis
- Error Rate Monitoring
- Trace Sampling Status

## Instrumentation

### Java Applications

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;

// Initialize OpenTelemetry
OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
    .setEndpoint("http://opentelemetry-collector:4317")
    .build();

SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
    .addSpanProcessor(new BatchSpanProcessor(spanExporter))
    .build();

OpenTelemetry openTelemetry = OpenTelemetrySdk.builder()
    .setTracerProvider(tracerProvider)
    .buildAndRegisterGlobal();
```

### Python Applications

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Initialize OpenTelemetry
otlp_exporter = OTLPSpanExporter(
    endpoint="opentelemetry-collector:4317",
    insecure=True
)

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)
```

### Go Applications

```go
import (
    "go.opentelemetry.io/exporter/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/sdk/trace"
)

// Initialize OpenTelemetry
exporter, _ := otlptracegrpc.New(
    context.Background(),
    otlptracegrpc.WithEndpoint("opentelemetry-collector:4317"),
)

tracerProvider := trace.NewTracerProvider(
    trace.WithBatcher(exporter),
)
```

### Node.js Applications

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'grpc://opentelemetry-collector:4317',
  }),
});

sdk.start();
```

## Configuration

### Variables

```hcl
enable_observability        = true
enable_otel_collector       = true
enable_jaeger              = true
enable_tempo               = true

otel_collector_mode        = "daemonset"    # daemonset, sidecar, statefulset
sampling_percentage        = 10             # 0-100%
jaeger_storage_type        = "memory"       # memory, elasticsearch, badger
tempo_storage_size         = "10Gi"
```

### Environment Variables (for applications)

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://opentelemetry-collector:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_SERVICE_NAME=my-service
OTEL_SDK_DISABLED=false
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1  # 10% sampling
```

## Accessing the UI

### Jaeger

```bash
kubectl port-forward -n observability svc/jaeger-query 16686:16686
# Open: http://localhost:16686
```

### Tempo

```bash
kubectl port-forward -n observability svc/tempo 3100:3100
# Open: http://localhost:3100 (limited UI)
# Use Grafana datasource for visualization
```

### Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Navigate to Explore → Select Jaeger or Tempo datasource
```

## Monitoring the Collector

### Health Check

```bash
kubectl exec -n observability <otel-pod> -- curl localhost:13133
```

### Metrics

```bash
kubectl port-forward -n observability svc/opentelemetry-collector 8888:8888
# Prometheus metrics at http://localhost:8888/metrics
```

### Logs

```bash
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector -f
```

## Performance Tuning

### Sampling

Adjust trace sampling to reduce storage and improve performance:

```hcl
sampling_percentage = 10  # Sample 10% of traces
```

### Batch Processing

OpenTelemetry Collector batches spans for efficiency:
- Batch size: 1024 spans
- Timeout: 10 seconds

### Resource Limits

```hcl
otel_collector_cpu_request    = "100m"
otel_collector_cpu_limit      = "500m"
otel_collector_memory_request = "128Mi"
otel_collector_memory_limit   = "512Mi"
```

## Trace Search

### In Jaeger

1. Open Jaeger UI
2. Select service from dropdown
3. Set filters (operation, tags, min duration)
4. Click "Find Traces"
5. Click trace to view span details

### In Grafana/Tempo

1. Grafana → Explore
2. Select Tempo datasource
3. Enter TraceID or click "Search"
4. View trace timeline and span details

## Troubleshooting

### No Traces Appearing

```bash
# Check OTEL Collector logs
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector

# Verify service is receiving data
kubectl exec -n observability <otel-pod> -- curl localhost:8888/metrics | grep otlp
```

### High Memory Usage

- Reduce sampling percentage
- Reduce batch size
- Enable memory limiter

### Traces Not Exported

```bash
# Check Jaeger is running
kubectl get pods -n observability -l app.kubernetes.io/name=jaeger

# Check Tempo is running
kubectl get pods -n observability -l app.kubernetes.io/name=tempo

# View OTEL Collector configuration
kubectl describe configmap opentelemetry-collector-config -n observability
```

## Network Policy Impact

Observability requires network access to:

```yaml
# OpenTelemetry Collector ingress
- From applications: TCP 4317 (gRPC), 4318 (HTTP)
- From Jaeger agents: TCP 14250, UDP 6831

# Collector egress
- To Jaeger: TCP 14250
- To Tempo: TCP 4317
- To Prometheus: TCP 8888
```

Update network policies to allow observability traffic.

## Storage Considerations

### Jaeger (Memory Mode)

- Default: In-memory storage
- Lost on pod restart
- Suitable for development/testing
- Use Elasticsearch/Badger for production

### Tempo

- Persistent volume: 10GB (default)
- Local storage for trace data
- Configurable retention
- Production-ready

## Cleanup

```bash
terraform destroy -target=module.observability

# Or manually
kubectl delete namespace observability
```

## Next Steps

1. Instrument applications with OpenTelemetry SDKs
2. Deploy applications with OTEL_EXPORTER_OTLP_ENDPOINT env vars
3. View traces in Jaeger or Tempo
4. Create custom dashboards in Grafana
5. Set up alerts based on trace metrics
