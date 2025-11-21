# Infrastructure Architecture Diagram

## Complete System Architecture

```mermaid
graph TB
    subgraph User["External Access"]
        HTTP["HTTP/HTTPS Requests"]
    end
    
    subgraph K8s["Kubernetes Cluster<br/>(Docker Desktop)"]
        
        subgraph IngressNS["🔓 Ingress Namespace<br/>(ingress-nginx)"]
            NGINX["NGINX Ingress Controller<br/>Service: NodePort"]
        end
        
        subgraph SecurityNS["🔐 Security Namespace"]
            CERT["Cert-Manager<br/>TLS Certificates"]
            EXTSC["External Secrets<br/>Secret Management"]
            ISTIO["Istio<br/>Service Mesh<br/>(optional)"]
        end
        
        subgraph AppNS["📦 Application Namespace<br/>(application)"]
            INGRESSAPP["Ingress<br/>echo-server.local"]
            APP1["Echo Server Pod 1<br/>Port 3000"]
            APP2["Echo Server Pod 2<br/>Port 3000"]
            APPSVC["Service ClusterIP<br/>Port 3000"]
        end
        
        subgraph DBNS["🗄️ Database Namespace<br/>(database)"]
            PG1["PostgreSQL Pod 1<br/>Primary"]
            PG2["PostgreSQL Pod 2<br/>Replica"]
            PG3["PostgreSQL Pod 3<br/>Replica"]
            DBSVC["Service FQDN<br/>postgres.database"]
            PV["PersistentVolumes<br/>Standard Storage"]
        end
        
        subgraph MonNS["📊 Monitoring Namespace<br/>(monitoring)"]
            PROM["Prometheus<br/>Metrics Scraper<br/>Port 9090"]
            GRAF["Grafana<br/>Visualization<br/>Port 3000"]
            GRAFDB["Grafana DB<br/>Datasources"]
        end
        
        subgraph ObsNS["🔍 Observability Namespace<br/>(observability)"]
            OTEL["OpenTelemetry<br/>Collector DaemonSet<br/>Ports: 4317/4318"]
            JAG["Jaeger<br/>Trace Storage<br/>Port: 16686"]
            TEMPO["Grafana Tempo<br/>Trace Backend<br/>10Gi Storage"]
        end
        
        subgraph CINSub["🚀 CI/CD Namespace<br/>(argocd)"]
            ARGO["ArgoCD Controller<br/>GitOps Manager<br/>Port: 8080"]
            ARGOSVC["ArgoCD Service<br/>Type: ClusterIP"]
        end
        
        %% Internal routing
        HTTP -->|Port 80/443| NGINX
        
        NGINX -->|Route| INGRESSAPP
        INGRESSAPP -->|Route| APPSVC
        APPSVC -->|Load Balance| APP1
        APPSVC -->|Load Balance| APP2
        
        APP1 -->|Connect| DBSVC
        APP2 -->|Connect| DBSVC
        
        DBSVC -->|Route| PG1
        DBSVC -->|Route| PG2
        DBSVC -->|Route| PG3
        
        PG1 -->|Persist| PV
        PG2 -->|Persist| PV
        PG3 -->|Persist| PV
        
        PROM -->|Scrape| APP1
        PROM -->|Scrape| APP2
        PROM -->|Scrape| NGINX
        PROM -->|Scrape| OTEL
        
        GRAF -->|Query| PROM
        GRAF -->|Query| JAG
        GRAF -->|Query| TEMPO
        
        OTEL -->|Collect Traces| APP1
        OTEL -->|Collect Traces| APP2
        OTEL -->|Send| JAG
        OTEL -->|Send| TEMPO
        
        JAG -->|Forward| TEMPO
        
        CERT -->|Issue Certs| INGRESSAPP
        EXTSC -->|Manage Secrets| PG1
        ISTIO -.->|Optional|APP1
        ISTIO -.->|Optional|APP2
        
        ARGO -->|Deploy from Git| APP1
        ARGO -->|Deploy from Git| APP2
        ARGO -->|Sync Policy| ARGOSVC
    end
    
    subgraph External["External Services"]
        GIT["Git Repository<br/>github.com/daucuong<br/>devops-assessment"]
    end
    
    ARGO -->|Pull Manifests| GIT
    GIT -->|Webhooks| ARGO
```

## Detailed Component Breakdown

```mermaid
graph LR
    subgraph Helm["Helm Charts Deployed"]
        H1["nginx-ingress<br/>v1.x"]
        H2["echo-server<br/>latest"]
        H3["postgresql<br/>v16"]
        H4["prometheus<br/>kube-prometheus"]
        H5["grafana<br/>v7.x"]
        H6["cert-manager<br/>optional"]
        H7["external-secrets<br/>optional"]
        H8["istio<br/>optional"]
        H9["argocd<br/>v5.51.6"]
        H10["opentelemetry<br/>v0.88.0"]
        H11["jaeger<br/>v0.71.1"]
        H12["grafana-tempo<br/>v1.6.1"]
    end
    
    subgraph NS["Target Namespaces"]
        NS1["ingress-nginx"]
        NS2["application"]
        NS3["database"]
        NS4["monitoring"]
        NS5["cert-manager"]
        NS6["external-secrets"]
        NS7["istio-system"]
        NS8["argocd"]
        NS9["observability"]
    end
    
    H1 --> NS1
    H2 --> NS2
    H3 --> NS3
    H4 --> NS4
    H5 --> NS4
    H6 --> NS5
    H7 --> NS6
    H8 --> NS7
    H9 --> NS8
    H10 --> NS9
    H11 --> NS9
    H12 --> NS9
```

## Data Flow: Request to Response

```mermaid
sequenceDiagram
    participant Client as Client
    participant NGINX as NGINX
    participant App as Echo Server
    participant DB as PostgreSQL
    participant Prom as Prometheus
    participant OTEL as OpenTelemetry
    participant Jaeger as Jaeger
    
    Client->>NGINX: HTTP GET /
    NGINX->>NGINX: Route lookup<br/>echo-server.local
    NGINX->>App: Forward request
    App->>App: Process request
    App->>OTEL: emit_trace()
    OTEL->>Jaeger: Store span
    App->>Prom: register_metric()
    App->>DB: Query (if needed)
    DB-->>App: Query result
    App-->>NGINX: Response 200 OK
    NGINX-->>Client: Response 200 OK
    Jaeger-->>Jaeger: Index trace
    Prom-->>Prom: Store metric
```

## Storage & Persistence Architecture

```mermaid
graph TB
    subgraph PV["PersistentVolumes"]
        PVG["Generic Storage Class<br/>Local to Docker Desktop"]
    end
    
    subgraph Data["Data Stores"]
        PGDATA["PostgreSQL<br/>Database Files<br/>HA Replication"]
        TEMPODATA["Grafana Tempo<br/>Trace Storage<br/>10Gi"]
        GRAFDB["Grafana DB<br/>Dashboards & Users<br/>Config"]
    end
    
    PVG --> PGDATA
    PVG --> TEMPODATA
    PVG --> GRAFDB
    
    subgraph Apps["Applications Reading Data"]
        APP["Echo Server"]
        GRAF["Grafana"]
        TEMPO["Tempo"]
    end
    
    PGDATA --> APP
    GRAFDB --> GRAF
    TEMPODATA --> TEMPO
```

## Resource Requirements Summary

```mermaid
graph TB
    CPU["CPU Allocation"]
    MEM["Memory Allocation"]
    DISK["Storage Allocation"]
    
    subgraph CPUBreakdown["CPU"]
        CPU1["NGINX: 100m req / 500m limit"]
        CPU2["Echo Server: 100m req / 500m limit"]
        CPU3["OTel: 100m req / 500m limit"]
        CPU4["Others: ~200m req"]
    end
    
    subgraph MEMBreakdown["Memory"]
        MEM1["NGINX: 90Mi req / 512Mi limit"]
        MEM2["Echo Server: 128Mi req / 512Mi limit"]
        MEM3["OTel: 128Mi req / 512Mi limit"]
        MEM4["Prometheus: ~1Gi"]
        MEM5["Grafana: ~500Mi"]
        MEM6["PostgreSQL: ~1Gi per instance"]
    end
    
    subgraph DISKBreakdown["Storage"]
        DISK1["PostgreSQL: ~5Gi total"]
        DISK2["Grafana Tempo: 10Gi"]
        DISK3["Prometheus: ~5Gi"]
        DISK4["System: ~2Gi"]
    end
    
    CPU --> CPUBreakdown
    MEM --> MEMBreakdown
    DISK --> DISKBreakdown
```

## Module Dependency Graph

```mermaid
graph TB
    MAIN["main.tf<br/>Root Module"]
    
    MAIN --> KUBECONFIG["kubeconfig<br/>~/.kube/config"]
    MAIN --> CONTEXT["kube-context<br/>docker-desktop"]
    
    MAIN --> IGX["ingress module"]
    MAIN --> SEC["security module"]
    MAIN --> MON["monitoring module"]
    MAIN --> DB["database module"]
    MAIN --> APP["application module"]
    MAIN --> CD["cicd module"]
    MAIN --> OBS["observability module"]
    
    IGX --> H1["NGINX Helm"]
    SEC --> H2["Cert-Manager Helm"]
    SEC --> H3["External Secrets Helm"]
    SEC --> H4["Istio Helm"]
    MON --> H5["Prometheus Helm"]
    MON --> H6["Grafana Helm"]
    DB --> H7["PostgreSQL Helm"]
    APP --> H8["Echo Server Helm"]
    CD --> H9["ArgoCD Helm"]
    OBS --> H10["OTel Helm"]
    OBS --> H11["Jaeger Helm"]
    OBS --> H12["Tempo Helm"]
    
    H5 -->|scrapes| APP
    H5 -->|scrapes| IGX
    H6 -->|visualizes| H5
    H6 -->|traces| H11
    H6 -->|traces| H12
    H8 -->|uses| H7
    H9 -->|deploys| H8
```

## High Availability & Disaster Recovery

```mermaid
graph TB
    subgraph HA["High Availability"]
        PG["PostgreSQL HA Cluster<br/>3 Instances<br/>Primary + 2 Replicas"]
        APP["Echo Server<br/>2 Replicas<br/>Load Balanced"]
        NGINX["NGINX<br/>Single Instance<br/>Configurable Replicas"]
    end
    
    subgraph DR["Disaster Recovery"]
        RTO["RTO: 5 minutes<br/>Recovery Time Objective"]
        RPO["RPO: 1 minute<br/>Recovery Point Objective"]
        PV["PersistentVolume<br/>Backups"]
        BACKUP["Automated Snapshots"]
    end
    
    subgraph FAILOVER["Failover Strategy"]
        DETECT["Automatic Detection<br/>Health Checks"]
        REROUTE["Service Rerouting<br/>Kubernetes DNS"]
        REPLICA["Use Replica Instance<br/>Promote to Primary"]
    end
    
    PG --> RTO
    PG --> RPO
    PV --> BACKUP
    DETECT --> REROUTE
    REROUTE --> REPLICA
```

## Security Architecture

```mermaid
graph TB
    subgraph Security["Security Layers"]
        TLS["TLS/SSL<br/>Cert-Manager<br/>Auto-renewal"]
        SECRETS["Secret Management<br/>External Secrets<br/>Kubernetes Secrets"]
        MESH["Service Mesh<br/>Istio<br/>mTLS, Authorization"]
        INGRESS["Ingress Auth<br/>NGINX Annotations<br/>OAuth2 Proxy"]
    end
    
    subgraph DataProtection["Data Protection"]
        DBPASS["DB Password<br/>Encrypted in Secrets"]
        GRAFPASS["Grafana Password<br/>Encrypted in Secrets"]
        ARGOPW["ArgoCD Password<br/>Encrypted in Secrets"]
    end
    
    subgraph AccessControl["Access Control"]
        RBAC["RBAC<br/>Service Accounts<br/>Role Bindings"]
        NETPOL["Network Policies<br/>Pod-to-Pod<br/>Namespace Isolation"]
    end
    
    TLS --> INGRESS
    SECRETS --> DBPASS
    SECRETS --> GRAFPASS
    SECRETS --> ARGOPW
```

## Observability Stack Integration

```mermaid
graph TB
    subgraph MetricsPath["Metrics Path"]
        APP1["Applications<br/>Prometheus<br/>Instrumentation"]
        PROM["Prometheus<br/>Time-Series<br/>Database"]
        GRAF["Grafana<br/>Visualization<br/>Dashboards"]
    end
    
    subgraph TracesPath["Traces Path"]
        APP2["Applications<br/>OTEL<br/>Instrumentation"]
        OTEL["OpenTelemetry<br/>Collector"]
        JAG["Jaeger<br/>Trace<br/>Storage"]
        TEMPO["Grafana Tempo<br/>Long-term<br/>Storage"]
    end
    
    subgraph LogsPath["Logs Path"]
        APP3["Applications<br/>stdout/stderr"]
        KUBECTL["kubectl logs<br/>or<br/>Log Aggregator"]
        LOGSTORE["Log Storage<br/>Optional"]
    end
    
    APP1 --> PROM
    PROM --> GRAF
    APP2 --> OTEL
    OTEL --> JAG
    JAG --> TEMPO
    TEMPO --> GRAF
    APP3 --> KUBECTL
    KUBECTL --> LOGSTORE
```
