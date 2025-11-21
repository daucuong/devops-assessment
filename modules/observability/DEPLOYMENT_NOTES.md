# Observability Module - Deployment Notes

## Status

### ✓ Deployed Successfully
- **Jaeger**: Distributed tracing backend with query UI
- **Jaeger Cassandra**: Trace storage backend
- **Jaeger Agents**: Running on all nodes for Thrift compact protocol support

### Currently Initializing
- **OpenTelemetry Collector**: Configuration being optimized
- **Grafana Tempo**: Storage initialization (high-available trace backend)

## Quick Start

### Access Jaeger UI

```bash
kubectl port-forward -n observability svc/jaeger-query 16686:16686
# Open: http://localhost:16686
```

### Verify Jaeger is Receiving Data

```bash
# Check Jaeger collector endpoint
kubectl get svc -n observability jaeger-collector
# gRPC: jaeger-collector.observability.svc:14250
# Thrift: jaeger:6831
```

### Check Pod Status

```bash
kubectl get pods -n observability
kubectl logs -n observability -l app.kubernetes.io/name=jaeger -f
```

## Components Architecture

### Jaeger Distributed Tracing
- **Agents**: Running as DaemonSet on all nodes
- **Collector**: Central collection point for traces
- **Query UI**: Search and visualize traces
- **Backend Storage**: Cassandra cluster for persistence

### Ports

| Component | Port | Protocol | Purpose |
|-----------|------|----------|---------|
| Jaeger Agent | 6831 | UDP | Thrift compact traces |
| Jaeger Agent | 6832 | UDP | Thrift binary traces |
| Jaeger Collector | 14250 | gRPC | Trace collection |
| Jaeger Query | 16686 | HTTP | UI access |

## Instrumentation Examples

### Sending Traces to Jaeger

### Go Application
```go
import (
    "go.opentelemetry.io/exporter/jaeger"
    "go.opentelemetry.io/sdk/trace"
)

exp, _ := jaeger.New(
    jaeger.WithCollectorEndpoint(
        jaeger.WithEndpoint("http://jaeger-collector.observability.svc:14250"),
    ),
)

tp := trace.NewTracerProvider(
    trace.WithBatcher(exp),
)
```

### Python Application
```python
from opentelemetry.exporter.jaeger import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831,
)

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)
```

### Node.js Application
```javascript
const jaeger = require('@opentelemetry/exporter-jaeger');
const { NodeSDK } = require('@opentelemetry/sdk-node');

const sdk = new NodeSDK({
  traceExporter: new jaeger.JaegerExporter({
    host: 'jaeger',
    port: 6831,
  }),
});

sdk.start();
```

## Troubleshooting

### OTEL Collector Configuration

The OpenTelemetry Collector is being configured to:
- Receive OTLP gRPC (port 4317)
- Receive OTLP HTTP (port 4318)
- Receive Jaeger gRPC (port 14250)
- Export traces to both Jaeger and Tempo
- Apply probabilistic sampling (default 10%)

If issues persist, check:
```bash
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector
```

### Tempo Storage

Tempo requires persistent storage. If not initializing:
```bash
kubectl describe pvc -n observability
kubectl logs -n observability tempo-0
```

### Cassandra Startup

Jaeger uses Cassandra for storage. It requires time to initialize:
```bash
kubectl get pods -n observability -l app.kubernetes.io/name=cassandra
# Wait for 3/3 Ready status
```

## Grafana Integration

Datasources have been created for:
- **Jaeger**: http://jaeger-query.observability:16686
- **Tempo**: http://tempo.observability:3100

Navigate to Grafana → Explore → Select datasource to search traces.

## Next Steps

1. **Instrument Applications**: Add OpenTelemetry SDKs to applications
2. **Configure Collectors**: Point applications to jaeger:6831 or OTEL collector:4317
3. **View Traces**: Open Jaeger UI to see distributed traces
4. **Create Dashboards**: Build Grafana dashboards for trace analysis
5. **Set Alerts**: Create alerts based on trace metrics

## Environment Variables for Apps

```bash
# Jaeger Direct
JAEGER_AGENT_HOST=jaeger
JAEGER_AGENT_PORT=6831

# Or OpenTelemetry Collector
OTEL_EXPORTER_OTLP_ENDPOINT=http://opentelemetry-collector:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_SERVICE_NAME=my-service
OTEL_SDK_DISABLED=false
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1  # 10% sampling
```

## Storage Considerations

### Cassandra (Jaeger)
- Default span retention: Depends on configuration
- Production-grade distributed database
- Requires 3 nodes for high availability

### Tempo (when fully deployed)
- Local storage: 10GB default (configurable)
- High-performance trace backend
- Optimized for cost and scale

## Monitoring

Monitor observability components:
```bash
kubectl top pods -n observability
kubectl get events -n observability --sort-by='.lastTimestamp'
```

## References

- Jaeger: https://www.jaegertracing.io/
- OpenTelemetry: https://opentelemetry.io/
- Grafana Tempo: https://grafana.com/oss/tempo/
