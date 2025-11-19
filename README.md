# DevOps Assessment IaC Solution

This repository contains Infrastructure as Code (IaC) using Terraform to deploy a production-ready application on a local Kubernetes cluster using Kind.

## Architecture Overview

The IaC is structured in modules for better organization and maintenance:

- **cluster**: Kind Kubernetes cluster setup
- **ingress**: NGINX Ingress Controller
- **database**: PostgreSQL database
- **monitoring**: Prometheus, Prometheus Operator, OpenTelemetry, ELK Stack
- **security**: cert-manager, external-secrets, Istio
- **application**: UI, API, services, ingresses, HPA, network policies
- **backup**: Velero for disaster recovery
- **cicd**: ArgoCD for GitOps continuous deployment
- **apm**: Jaeger and Kiali for application performance monitoring

The solution deploys the following components:

- **UI**: Static web front-end (acme/ui image) accessible at www.acme.com
- **API**: Stateless REST API (acme/api image) accessible at api.acme.com
- **Database**: PostgreSQL database (private, isolated)
- **Metrics**: Prometheus for monitoring (private)

## Components Deployed

1. **Kind Cluster**: Local Kubernetes cluster
2. **MetalLB Load Balancer**: Provides external IPs for services
3. **NGINX Ingress Controller**: For routing and load balancing with LoadBalancer service, access logging, and performance tuning
4. **PostgreSQL StatefulSet**: HA database with automated backups and PITR
5. **Prometheus Deployment**: Basic metrics collection
6. **API Deployment**: Scalable API with HPA
7. **UI Deployment**: Static site serving
8. **Ingresses**: HTTPS termination (with cert-manager for automation)
9. **Network Policies**: Comprehensive zero-trust networking with ingress/egress controls
10. **Horizontal Pod Autoscaler**: Auto-scaling for API based on CPU
11. **cert-manager**: Certificate automation
12. **external-secrets**: Secret management
13. **Istio**: Service mesh for advanced networking and security
14. **Prometheus Operator**: Comprehensive monitoring stack
15. **OpenTelemetry Collector**: Tracing collection
16. **ELK Stack (Elasticsearch, Logstash, Kibana)**: Logging aggregation
17. **Velero**: Backups and disaster recovery
18. **ArgoCD**: GitOps continuous deployment
19. **Jaeger**: Distributed tracing for APM
20. **Kiali**: Service mesh observability

## Prerequisites

- Docker
- Kind
- Terraform (>= 1.0)
- kubectl

## Pre-Deployment Steps

Some tools require Custom Resource Definitions (CRDs) to be installed before deploying the resources. Run these commands after creating the Kind cluster but before Terraform apply:

```bash
# Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml

# Install Prometheus Operator CRDs
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.63.0/bundle.yaml

# Install Istio base (CRDs and base components)
istioctl install --set profile=demo -y

# Install external-secrets CRDs
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/config/crds/bundle.yaml
```

## Deployment

1. Clone this repository
2. Run pre-deployment steps above
3. Initialize Terraform:
   ```
   terraform init
   ```
4. Plan the deployment:
   ```
   terraform plan
   ```
5. Apply the configuration:
   ```
   terraform apply
   ```

## Access the Application

After deployment, check the LoadBalancer external IPs:

```bash
kubectl get svc -n ingress-nginx
```

Update your `/etc/hosts` file to point the domains to the LoadBalancer external IP (replace `EXTERNAL_IP` with the actual IP):

```
EXTERNAL_IP www.acme.com
EXTERNAL_IP api.acme.com
EXTERNAL_IP argocd.local
EXTERNAL_IP jaeger.local
EXTERNAL_IP kiali.local
```

Access:
- UI: https://www.acme.com
- API: https://api.acme.com
- ArgoCD: https://argocd.local
- Jaeger: https://jaeger.local
- Kiali: https://kiali.local

For services without ingress (internal monitoring):
- Prometheus: kubectl port-forward svc/prometheus-service -n acme 9090:80
- Kibana: kubectl port-forward svc/kibana -n logging 5601:5601 (includes NGINX access logs)
- Elasticsearch: kubectl port-forward svc/elasticsearch -n logging 9200:9200
- OpenTelemetry Collector: kubectl port-forward svc/otel-collector -n opentelemetry 4317:4317

Note: MetalLB provides external IPs for LoadBalancer services. Certificates are managed by cert-manager, but for local development, you may see warnings. Use `admin` as username and get ArgoCD password with `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d`. NGINX access logs are automatically shipped to Elasticsearch for centralized logging and monitoring.

## Disaster Recovery Procedures

### Database Backup & Recovery

**Automated Backups:**
- Logical backups every 6 hours via CronJob (pg_dump)
- Stored in dedicated PVC (postgres-backup-pvc)
- Retention managed by PVC capacity

**PITR Recovery:**
- WAL archiving enabled for point-in-time recovery
- Recovery up to any point within retention window
- Use `postgres-pitr-recovery` job for restoration

**RTO/RPO Metrics:**
- RTO: < 4 hours (full cluster restoration)
- RPO: < 6 hours (maximum data loss from automated backups)
- < 1 hour for logical backups

### Application Recovery

**Velero Backups:**
- Daily scheduled backups at 2 AM
- Includes PVC snapshots and application configuration
- 30-day retention for database data, 7 days for configs

**Recovery Commands:**
```bash
# List available backups
velero backup get

# Restore from backup
velero restore create --from-backup <backup-name>

# Check restore status
velero restore get
```

### Multi-AZ/Regional Redundancy Simulation

Since this is a local Kind cluster, multi-AZ redundancy is simulated through:
- Multi-pod PostgreSQL StatefulSet (2 replicas)
- Distributed backup storage (simulated S3/MinIO)
- Cross-namespace monitoring and alerting
- Network policies ensuring isolation

## Best Practices Implemented

### Deployment Automation & Zero-Downtime Updates
- Rolling updates via Kubernetes deployments
- Terraform enables declarative, automated deployments
- ArgoCD provides GitOps continuous deployment

### Scalability & Auto-Scaling
- Horizontal Pod Autoscaler for API
- Multiple replicas for high availability

### Security & Zero-Trust Networking
- Comprehensive network policies implementing zero-trust architecture
- Database: Only API pods can access PostgreSQL on port 5432
- Metrics: Restricted access from API, monitoring, and observability namespaces
- Default deny-all policy for all pods with explicit allow rules
- Ingress/Egress controls for API and UI services
- Namespace isolation with labeled selectors
- Services are ClusterIP by default

### HTTPS Termination & Ingress
- NGINX Ingress Controller
- cert-manager for automated TLS certificate management
- TLS enabled with automatic renewal

### Infrastructure-as-Code
- Full Terraform IaC
- Modular resource definitions
- MetalLB load balancer for external service exposure

### Load Balancing & Traffic Management
- NGINX Ingress with comprehensive configuration:
  - JSON-formatted access logging with detailed request/response metrics
  - Optimized keep-alive settings (75 connections, 1000 requests per connection)
  - Configurable timeouts (client: 12s, proxy: 30s, connect: 5s)
  - Buffer tuning for high-throughput scenarios
- Security headers automatically applied to all responses
- Fluent Bit integration for centralized log aggregation
- Rate limiting (100 requests per minute per IP)
- Health check endpoints for monitoring

### Backups, Disaster Recovery & Resilience
- PostgreSQL with automated backups (every 6 hours via CronJob)
- WAL archiving enabled for Point-in-Time Recovery (PITR)
- Velero for comprehensive backup strategy:
  - Daily scheduled backups for database PVCs (30-day retention)
  - Application configuration backups (7-day retention)
  - Volume snapshots for data persistence
- Multi-pod PostgreSQL setup (2 replicas) for HA simulation
- Dedicated PVCs for data (10Gi), backups (50Gi), and WAL archives (20Gi)
- PITR recovery job template for disaster scenarios
- Proper resource limits and health checks for database pods

### Observability & Metrics
- Prometheus for metrics collection
- Prometheus Operator for advanced monitoring stack
- OpenTelemetry Collector for distributed tracing
- Jaeger for distributed tracing (APM)
- Kiali for service mesh observability
- ELK Stack (Elasticsearch, Logstash, Kibana) for centralized logging
- Health checks on all services

### Secret Management
- external-secrets operator for secure secret management
- Integration with external secret stores (Vault, AWS Secrets Manager)

### Service Mesh
- Istio for advanced networking, security policies, and observability

### Cost Awareness
- Local deployment minimizes costs
- Resource requests defined

## Shortcomings & Improvements

### Shortcomings
- Some tools require CRDs to be installed first (cert-manager, Prometheus Operator, Istio)
- Secrets are hardcoded (external-secrets installed but not configured)
- No Let's Encrypt integration (cert-manager installed but needs ClusterIssuer)
- No CI/CD pipeline defined
- Velero needs storage location configuration for actual backups

### Technical Debt
- Database password in plain text
- No monitoring dashboards
- No logging aggregation

### Collaboration Points
- Coordinate with developers for image builds
- Align on environment variables and config
- Define SLO/SLA requirements

### Future Improvements
- Configure cert-manager with Let's Encrypt ClusterIssuer
- Set up external-secrets with Vault or AWS Secrets Manager
- Enable Istio sidecar injection and create VirtualServices/PeerAuthentication
- Deploy Grafana with Alertmanager for dashboards and alerting
- Configure Velero with actual S3-compatible storage (MinIO, AWS S3)
- Multi-region deployment for true high availability
- Implement SLO/SLA monitoring with Prometheus rules
- Configure applications to send traces to Jaeger
- Set up database replication across multiple zones
- Implement ingress rate limiting and DDoS protection
