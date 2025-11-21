# Kubernetes Infrastructure Architecture

## System Overview

This Terraform configuration deploys a comprehensive Kubernetes platform on Docker Desktop with the following components:

### Core Components

1. **Ingress Layer** - NGINX Ingress Controller
2. **Application** - Echo Server microservice
3. **Database** - PostgreSQL HA cluster
4. **Monitoring** - Prometheus + Grafana
5. **Security** - Cert-Manager, External Secrets, Istio
6. **CI/CD** - ArgoCD for GitOps
7. **Observability** - OpenTelemetry Collector, Jaeger, Grafana Tempo

## Architecture Diagram

```mermaid
graph TB
    subgraph Kubernetes["Kubernetes Cluster (Docker Desktop)"]
        
        subgraph Ingress["Ingress Layer"]
            NGINX["NGINX Ingress Controller<br/>Port: NodePort"]
        end
        
        subgraph AppLayer["Application Namespace"]
            APP["Echo Server<br/>2 Replicas<br/>Port: 3000"]
            APPINGRESS["App Ingress<br/>echo-server.local"]
        end
        
        subgraph Security["Security Namespace"]
            CERTMGR["Cert-Manager<br/>TLS Certificates"]
            EXTSECRETS["External Secrets<br/>Operator"]
            ISTIO["Istio Service Mesh<br/>optional"]
        end
        
        subgraph Database["Database Namespace"]
            PG["PostgreSQL HA Cluster<br/>3 Instances<br/>RTO: 5min | RPO: 1min"]
            PGVOL["PersistentVolumes<br/>Storage Class: standard"]
        end
        
        subgraph Monitoring["Monitoring Namespace"]
            PROM["Prometheus<br/>Metrics Collection"]
            GRAF["Grafana<br/>Visualization<br/>Port: 3000"]
        end
        
        subgraph Observability["Observability Namespace"]
            OTEL["OpenTelemetry<br/>Collector<br/>DaemonSet"]
            JAEGER["Jaeger<br/>Distributed Tracing<br/>Storage: Memory"]
            TEMPO["Grafana Tempo<br/>Trace Backend<br/>10Gi Storage"]
        end
        
        subgraph CICD["CI/CD Namespace"]
            ARGOCD["ArgoCD<br/>GitOps Controller<br/>Sync: Automated"]
            GITREPO["Git Repository<br/>github.com/daucuong/devops-assessment"]
        end
        
        %% Connections
        NGINX -->|routes| APPINGRESS
        APPINGRESS -->|routes| APP
        APP -->|queries| PG
        PROM -->|scrapes| APP
        PROM -->|scrapes| NGINX
        GRAF -->|visualizes| PROM
        GRAF -->|datasource| JAEGER
        GRAF -->|datasource| TEMPO
        OTEL -->|collects traces| APP
        JAEGER -->|stores| TEMPO
        ARGOCD -->|syncs from| GITREPO
        ARGOCD -->|deploys| APP
        CERTMGR -->|issues certs| APPINGRESS
        EXTSECRETS -->|manages| PG
        ISTIO -.->|optional| APP
        
        %% Storage
        PG -->|uses| PGVOL
        TEMPO -->|uses| PGVOL
    end
    
    User["👤 Users<br/>Port 8080+"]
    GitRepo["Git Repository<br/>Source Control"]
    
    User -->|HTTP| NGINX
    GitRepo -->|pull| ARGOCD
```

## Module Dependencies

```mermaid
graph TB
    Main["main.tf<br/>Provider Config"]
    
    Main -->|kubernetes| KubeProvider["Kubernetes Provider<br/>Config: ~/.kube/config"]
    Main -->|helm| HelmProvider["Helm Provider<br/>Kubernetes Backed"]
    
    Main --> Ingress["ingress module<br/>NGINX Controller"]
    Main --> Security["security module<br/>Cert-Manager, ESO, Istio"]
    Main --> Monitoring["monitoring module<br/>Prometheus + Grafana"]
    Main --> Database["database module<br/>PostgreSQL HA"]
    Main --> App["application module<br/>Echo Server"]
    Main --> CICD["cicd module<br/>ArgoCD"]
    Main --> Observability["observability module<br/>OTEL, Jaeger, Tempo"]
    
    Database -->|persistent data| Monitoring
    App -->|metrics| Monitoring
    Ingress -->|http routing| App
    Security -->|certificates| Ingress
    Security -->|secrets| Database
    CICD -->|deploys| App
    Observability -->|traces| Monitoring
    Observability -->|traces| App
```

## Data Flow Diagram

```mermaid
sequenceDiagram
    participant User as User Request
    participant NGINX as NGINX Ingress
    participant App as Echo Server
    participant DB as PostgreSQL
    participant Prom as Prometheus
    participant OTEL as OpenTelemetry
    participant Jaeger as Jaeger
    
    User->>NGINX: HTTP Request
    NGINX->>App: Route (echo-server.local)
    App->>App: Process Request
    App->>Prom: Emit Metrics
    App->>OTEL: Send Trace
    App->>DB: Query (if needed)
    DB-->>App: Return Data
    App-->>NGINX: HTTP Response
    NGINX-->>User: HTTP Response
    OTEL->>Jaeger: Persist Trace
    Prom->>Prom: Scrape & Store
```

## Namespace Organization

```mermaid
graph TB
    Cluster["Kubernetes Cluster"]
    
    Cluster --> NS1["ingress-nginx<br/>NGINX Ingress Controller"]
    Cluster --> NS2["cert-manager<br/>Certificate Management"]
    Cluster --> NS3["application<br/>Echo Server App"]
    Cluster --> NS4["database<br/>PostgreSQL HA"]
    Cluster --> NS5["monitoring<br/>Prometheus + Grafana"]
    Cluster --> NS6["argocd<br/>GitOps Controller"]
    Cluster --> NS7["observability<br/>OTEL, Jaeger, Tempo"]
    
    NS1 ---|Helm| Cluster
    NS2 ---|Helm| Cluster
    NS3 ---|Helm| Cluster
    NS4 ---|Helm| Cluster
    NS5 ---|Helm| Cluster
    NS6 ---|Helm| Cluster
    NS7 ---|Helm| Cluster
```

## Configuration Hierarchy

```mermaid
graph LR
    TF["Terraform Root<br/>main.tf"]
    VAR["variables.tf<br/>Input Variables"]
    TFVARS["terraform.tfvars<br/>Variable Values"]
    OUT["outputs.tf<br/>Output Values"]
    
    TF --> VAR
    VAR --> TFVARS
    TF --> OUT
    
    TF -->|module| MOD["Modules<br/>7 modules"]
    MOD -->|variables| VAR
    MOD -->|outputs| OUT
```

## Resource Summary

| Component | Type | Count | Namespace | Purpose |
|-----------|------|-------|-----------|---------|
| NGINX Ingress | Helm Chart | 1 | ingress-nginx | HTTP(S) routing |
| Echo Server | Helm Chart | 1 | application | Demo application (2 replicas) |
| PostgreSQL | Helm Chart | 1 | database | HA cluster (3 instances) |
| Prometheus | Helm Chart | 1 | monitoring | Metrics collection |
| Grafana | Helm Chart | 1 | monitoring | Visualization & dashboards |
| Cert-Manager | Helm Chart | 1 (optional) | cert-manager | TLS certificate issuing |
| External Secrets | Helm Chart | 1 (optional) | external-secrets | Secret management |
| Istio | Helm Chart | 1 (optional) | istio-system | Service mesh |
| ArgoCD | Helm Chart | 1 | argocd | GitOps continuous deployment |
| OpenTelemetry | Helm Chart | 1 | observability | Trace/metric collection |
| Jaeger | Helm Chart | 1 | observability | Distributed tracing |
| Grafana Tempo | Helm Chart | 1 | observability | Trace backend |

## Key Features

### High Availability
- PostgreSQL HA cluster with 3 instances
- RTO: 5 minutes, RPO: 1 minute
- Persistent volume storage

### Security
- Cert-Manager for automatic TLS certificates
- External Secrets Operator for credential management
- Optional Istio service mesh for advanced traffic management

### Observability
- Prometheus for metrics collection
- Grafana for visualization
- OpenTelemetry Collector for distributed tracing
- Jaeger for trace visualization
- Grafana Tempo for trace backend (10Gi storage)

### GitOps
- ArgoCD for declarative application deployment
- Automated sync policy
- Auto-prune and self-healing enabled
- Git repository as source of truth

### Resource Management
- CPU/Memory requests and limits configured
- NGINX: 100m request / 500m limit
- Echo Server: 100m request / 500m limit
- OTel Collector: 100m request / 500m limit
