# ACME Platform Infrastructure Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [System Components](#system-components)
4. [Deployment Architecture](#deployment-architecture)
5. [Security](#security)
6. [Scalability](#scalability)
7. [Disaster Recovery](#disaster-recovery)
8. [Observability](#observability)
9. [Recent Improvements](#recent-improvements-latest-updates)
10. [References](#references)

---

## Overview

This infrastructure implements the ACME platform—a containerized, cloud-native application stack with full high availability, automatic scaling, and comprehensive observability. The solution is deployed on Kubernetes using Terraform for infrastructure-as-code, with Helm for package management and ArgoCD for GitOps-based deployments.

**Technology Stack:**
- **Orchestration:** Kubernetes (any distribution)
- **Infrastructure as Code:** Terraform
- **Package Management:** Helm
- **GitOps:** ArgoCD
- **Service Mesh:** Istio (optional)
- **Ingress:** NGINX Ingress Controller
- **Database:** PostgreSQL (HA Cluster via CloudNativePG)
- **Observability:** Prometheus, Grafana, OpenTelemetry, Jaeger, Tempo
- **Security:** cert-manager, External Secrets Operator, Network Policies
- **Backup & Disaster Recovery:** Velero (backup orchestration and restoration)

---

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet / DNS                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴──────────────────┐
         │                                  │
    ┌──────────────────────────────────────────┐
    │         www.acme.com (Single Domain)     │
    │  /       -> UI                           │
    │  /api    -> API                          │
    └────┬─────────────────────────────────────┘
         │
    ┌────▼──────────────────────────────────────┐
    │  NGINX Ingress Controller(TLS Termination)│
    │  - LoadBalancer Service (2 replicas HA)   │
    │  - SSL/TLS via cert-manager (acme-tls)    │
    │  - Request timeouts: 600s                 │
    │  - Pod Anti-Affinity enabled              │
    └────┬──────────────────────────────────────┘
         │
    ┌────▼────────────────────────────────────────┐
    │         Kubernetes Cluster                  │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Application Namespace               │   │
    │  │  ├─ UI Pods (acme/ui)                │   │
    │  │  │  └─ 2+ Replicas (HPA enabled)     │   │
    │  │  └─ API Pods (acme/api)              │   │
    │  │     └─ 2+ Replicas (HPA enabled)     │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Observability Namespace             │   │
    │  │  ├─ OpenTelemetry Collector          │   │
    │  │  ├─ Jaeger (Distributed Tracing)     │   │
    │  │  └─ Tempo (Trace Storage)            │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Monitoring Namespace                │   │
    │  │  ├─ Prometheus                       │   │
    │  │  └─ Grafana                          │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Database Namespace                  │   │
    │  │  └─ PostgreSQL HA Cluster (3 nodes)  │   │
    │  │     ├─ Primary                       │   │
    │  │     └─ Replicas + Standby            │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Security Namespace                  │   │
    │  │  ├─ cert-manager                     │   │
    │  │  ├─ External Secrets Operator        │   │
    │  │  └─ Istio (optional service mesh)    │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  CI/CD Namespace (argocd)            │   │
    │  │  └─ ArgoCD Controller                │   │
    │  │     └─ Git-driven deployments        │   │
    │  └──────────────────────────────────────┘   │
    │                                             │
    │  ┌──────────────────────────────────────┐   │
    │  │  Backup Namespace (velero)           │   │
    │  │  └─ Velero Server                    │   │
    │  │     ├─ Scheduled backups             │   │
    │  │     └─ Backup/restore operations     │   │
    │  └──────────────────────────────────────┘   │
    └────┬────────────────────────────────────────┘
         │
    ┌────▼──────────────────────────────────────┐
    │  Persistent Storage                       │
    │  ├─ PostgreSQL PVs (3x for HA cluster)    │
    │  ├─ Tempo Trace Storage (10Gi)            │
    │  └─ Jaeger Storage (if using DB backend)  │
    └───────────────────────────────────────────┘
```

---

## System Components

### 1. **User Interface (UI)**
- **Image:** `acme/ui`
- **Path:** `www.acme.com/` (root path, catch-all)
- **Ports:** 80/443 (exposed via NGINX Ingress)
- **Public:** Yes
- **Replicas:** 2+ (configurable via HPA)
- **Description:** Static/client-side web frontend serving the ACME UI
- **Resource Limits:** 100m CPU request, 500m limit; 128Mi memory request, 512Mi limit

### 2. **REST API**
- **Image:** `acme/api`
- **Path:** `www.acme.com/api` (path-based routing, replaces domain-based api.acme.com)
- **Port:** 443 (HTTPS only, no HTTP)
- **Public:** Yes
- **Replicas:** 2+ (configurable via HPA)
- **Request Timeout:** 600 seconds (connect, send, read, body)
- **Description:** Stateless REST API backend serving application logic
- **Environment Variables:**
  - `POSTGRES_URL` - Connection string to PostgreSQL
  - `METRICS_URL` - Endpoint for metrics collection
- **Resource Limits:** 100m CPU request, 500m limit; 128Mi memory request, 512Mi limit
- **Avoids CORS issues:** If the frontend is served from acme.com, calling acme.com/api avoids cross-origin configuration.

### 3. **PostgreSQL Database**
- **Version:** 16 (latest)
- **Port:** 5432
- **Public:** No (private subnet, cluster-isolated)
- **Instances:** 3 (HA cluster configuration)
- **High Availability:** CloudNativePG operator for multi-node cluster
  - 1 Primary + 2 Read Replicas
  - Automatic failover
  - Streaming replication
- **Persistent Storage:** 
  - Storage Class: `standard` (configurable)
  - Each instance gets dedicated PVC
- **Backup & Recovery:**
  - RTO: 5 minutes (Recovery Time Objective)
  - RPO: 1 minute (Recovery Point Objective)
  - Automated backups via WAL archiving

### 4. **Metrics Collector**
- **Purpose:** Prometheus metrics aggregation
- **Port:** 8888 (internal collection)
- **Public:** No
- **Components:**
  - OpenTelemetry Collector (DaemonSet/Deployment)
  - Prometheus server
  - Custom metrics scrapers

---

## Deployment Architecture

### Kubernetes Namespaces

| Namespace | Purpose | Status |
|-----------|---------|--------|
| `application` | UI & API Pods | Core |
| `database` | PostgreSQL cluster | Core |
| `monitoring` | Prometheus & Grafana | Optional |
| `observability` | OpenTelemetry, Jaeger, Tempo | Optional |
| `ingress-nginx` | NGINX Ingress Controller | Core |
| `cert-manager` | Certificate management | Optional (recommended) |
| `argocd` | CI/CD orchestration | Optional |

### Helm Charts Deployed

| Chart | Source | Namespace | Purpose |
|-------|--------|-----------|---------|
| ACME Application | Local (`./helm/acme`) | `application` | UI & API services |
| NGINX Ingress | `ingress-nginx` | `ingress-nginx` | Traffic routing & TLS |
| cert-manager | `jetstack/cert-manager` | `cert-manager` | SSL/TLS certificate automation |
| External Secrets | `external-secrets/external-secrets` | `external-secrets` | Secret management from external vaults |
| Istio | `istio/istio` | `istio-system` | Service mesh (optional) |
| Prometheus | `kube-prometheus-stack` | `monitoring` | Metrics collection & storage |
| Grafana | `grafana/grafana` | `monitoring` | Metrics visualization |
| OpenTelemetry Collector | `open-telemetry/opentelemetry-collector` | `observability` | Trace & metric collection |
| Jaeger | `jaegertracing/jaeger` | `observability` | Distributed tracing (query UI) |
| Grafana Tempo | `grafana/tempo` | `observability` | Trace storage backend |
| CloudNativePG | `cloudnative-pg/cloudnative-pg` | `database` | PostgreSQL operator |
| ArgoCD | `argoproj/argo-cd` | `argocd` | GitOps continuous deployment |
| Velero | `vmware-tanzu/velero` | `velero` | Backup & disaster recovery |

### Terraform Modules

```
modules/
├── application/     # ACME UI & API Helm chart deployment
├── ingress/         # NGINX Ingress Controller setup
├── security/        # cert-manager, External Secrets, Istio, Network Policies
├── database/        # PostgreSQL HA cluster via CloudNativePG
├── monitoring/      # Prometheus & Grafana
├── cicd/            # ArgoCD deployment
├── observability/   # OpenTelemetry, Jaeger, Tempo
└── backup/          # Velero backup & disaster recovery
```

---

## Security

### HTTPS/TLS Termination
- **NGINX Ingress Controller** handles all TLS termination
- **cert-manager** automates certificate provisioning and renewal (when enabled)
- **TLS Secret:** `acme-tls` (referenced in Ingress resource)
- **Certificate Lifecycle:**
  - Supports Let's Encrypt (staging and production)
  - Configurable via Ingress annotations: `cert-manager.io/cluster-issuer`
  - Default issuer: `letsencrypt-prod` (optional, when cert-manager enabled)
- **Request Timeouts:**
  - Proxy Connect Timeout: 600 seconds
  - Proxy Send Timeout: 600 seconds
  - Proxy Read Timeout: 600 seconds
  - Proxy Body Timeout: 600 seconds

### Secret Management
- **External Secrets Operator** (optional) integrates with external vaults:
  - AWS Secrets Manager
  - HashiCorp Vault
  - Azure Key Vault
  - Google Secret Manager
- Database passwords stored as Kubernetes Secrets
- Sensitive Terraform variables marked with `sensitive = true`

### Network Security

#### Network Policies
- Implemented in `modules/security/network_policy.tf`
- **Egress Rules:** Restrict outbound traffic
  - API → PostgreSQL only (port 5432)
  - API → Metrics Collector only
  - API → External APIs (configurable)
- **Ingress Rules:** Restrict inbound traffic
  - NGINX → API (port 3000)
  - NGINX → UI (port 3000)
  - Database accessible only from application namespace
  - Observability components access limited to collection endpoints

#### Service Mesh (Istio - Optional)
- Provides mTLS between services
- Fine-grained traffic policies
- Circuit breakers & retries
- Rate limiting & fault injection for testing

### Database Security
- PostgreSQL runs in private namespace (not exposed to internet)
- Authentication: username/password (configurable)
- Network Policies restrict pod-to-pod access
- No public IP assigned to database service

---

## Scalability

### High Availability (NGINX Ingress)
- **Replicas:** 2 (minimum for HA)
- **Pod Disruption Budget:** Ensures 1 replica remains during maintenance
- **Pod Anti-Affinity:** Spreads replicas across different nodes
- **Metrics:** Enabled for Prometheus monitoring
- **Security:** Non-root container, read-only filesystem

### Horizontal Pod Autoscaling (HPA)
- **UI & API Pods:** Auto-scale based on CPU (50%) and Memory (70%) utilization
- **Configured Replicas:** 2 (minimum) → configurable maximum (default 10)
- **Metrics Source:** Kubernetes Metrics Server (built-in)

### Resource Management
```
Application Pods:
  CPU Request:     100m
  CPU Limit:       500m
  Memory Request:  128Mi
  Memory Limit:    512Mi

NGINX Controller (HA):
  Replicas:        2
  CPU Request:     100m
  CPU Limit:       500m
  Memory Request:  90Mi
  Memory Limit:    512Mi
  Pod Disruption:  minAvailable = 1
  Client timeout:  600s
  Upstream timeout: 60s

OpenTelemetry Collector:
  CPU Request:     100m
  CPU Limit:       500m
  Memory Request:  128Mi
  Memory Limit:    512Mi
```

### Database Scalability
- **CloudNativePG HA cluster** with 3 instances
- Read replicas handle read-heavy workloads
- Stateless API layer scales independently
- Connection pooling recommended (PgBouncer or similar)

---

## Disaster Recovery

### Strategy

| Objective | Target | Implementation |
|-----------|--------|-----------------|
| **RTO** (Recovery Time) | 5 minutes | CloudNativePG failover automation |
| **RPO** (Recovery Point) | 1 minute | Continuous WAL streaming replication |
| **Backup Frequency** | Continuous | Streaming replication + WAL archiving |

### PostgreSQL HA Features
- **Automatic Failover:** Primary → Replica promotion (< 1 minute)
- **Streaming Replication:** Real-time WAL log shipping
- **Standby Clusters:** Support for geographically distributed replicas
- **Point-in-Time Recovery (PITR):** Restore to any point in transaction history

### Application Layer Recovery
- **Stateless Design:** Pods are ephemeral; data persists in PostgreSQL
- **ConfigMaps & Secrets:** Version-controlled via Git (ArgoCD)
- **Persistent Volumes:** PVC-backed storage survives pod restarts
- **Image Registry:** Container images must be accessible during recovery

### Velero Backup & Disaster Recovery
- **Scheduled Backups:** Automated daily backups of database and application configs
  - Database backups: Daily at 2 AM UTC
  - Application config backups: Daily at 3 AM UTC
- **Backup Retention:** 30 days default (configurable) 1 year for enterprise
- **Backup Scope:**
  - **Database:** PersistentVolumeClaims from `database` namespace
  - **Application Config:** ConfigMaps, Secrets, Deployments, Services, Ingresses from `application` namespace
- **Volume Snapshots:** Enabled for PVC-backed data
- **Storage Locations:** Local storage
- **Restore Capabilities:**
  - Point-in-time restore of specific resources
  - Full cluster restore from backups
  - Restore to same or different cluster
- **Monitoring:** Prometheus metrics from Velero for backup success/failure tracking

---

## Observability

### Metrics Collection

**Prometheus** (port 9090)
- Scrapes Kubernetes metrics from:
  - Node exporter
  - cAdvisor
  - Kubelet
  - Application custom metrics (via OTLP)
- 15-day default retention
- Alert rules can be defined for SLA monitoring

**Metrics Exposed by Application:**
- HTTP request rate & latency
- Error rates
- Custom business metrics (configurable)

### Visualization

**Grafana** (port 3000)
- Pre-built dashboards:
  - Kubernetes cluster health
  - Node & pod resource utilization
  - Application performance
  - Database health & replication status
- User-defined dashboards for custom metrics
- Alert integration with PagerDuty, Slack, etc.

### Distributed Tracing

**OpenTelemetry Collector**
- Collects traces from instrumented applications
- Protocols supported:
  - OTLP gRPC (port 4317)
  - OTLP HTTP (port 4318)
  - Jaeger (port 14250)
  - Other legacy protocols

**Jaeger** (Distributed Tracing)
- Query UI: traces visualization & search
- Backend storage: in-memory or Elasticsearch-backed
- Sampling: 10% default (configurable)

**Grafana Tempo** (Trace Storage)
- Long-term trace storage (alternative to Jaeger)
- Storage backend: PersistentVolume (10Gi default)
- Integrated with Grafana for trace visualization

### Health Checks
- **Liveness Probe:** Pod restart on failure
- **Readiness Probe:** Remove from load balancer if not ready
- **Startup Probe:** Support for slow-starting applications

---

## Recent Improvements (Latest Updates)

### Ingress Routing Enhancement
- **Changed:** Routing model from multi-domain (`www.acme.com` + `api.acme.com`) to path-based routing
- **New Model:** Single domain (`www.acme.com`) with path-based routing:
  - `www.acme.com/` → UI service
  - `www.acme.com/api` → API service
- **Benefits:** Simpler TLS certificate management, cleaner DNS configuration, reduced operational complexity

### NGINX Ingress Controller Hardening
- **High Availability:** 2 replicas with pod anti-affinity for node distribution
- **Reliability:** Pod Disruption Budget ensures 1 replica always available during maintenance
- **Request Handling:**
  - Client body timeout: 600s
  - Client header timeout: 600s
  - Upstream keepalive: 60s with 100 requests per connection
  - Max body size: 20MB
- **Security:** Non-root container with read-only filesystem
- **Observability:** Metrics enabled for Prometheus monitoring

---

## References

- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [NGINX Ingress Configuration](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/)
- [OpenTelemetry Best Practices](https://opentelemetry.io/docs/best-practices/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Velero Documentation](https://velero.io/docs/main/)
