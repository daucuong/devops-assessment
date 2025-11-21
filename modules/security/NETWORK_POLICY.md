# Network Policy Configuration

This module implements Kubernetes network policies to enforce a security model where all components run in private subnets while allowing the application to be publicly accessible.

## Architecture

### Network Isolation Model

1. **Private Components**
   - Security (cert-manager, external-secrets, istio)
   - Database
   - Monitoring
   - Ingress controller

2. **Public Access**
   - Application namespace (accessible via ingress controller)

## Network Policies

### Default Deny Policies
- `default-deny-ingress`: Deny all ingress traffic in security namespace by default
- `default-deny-egress`: Deny all egress traffic in security namespace by default

These ensure all communication is explicitly allowed only where needed.

### DNS Access
- `allow-dns`: All security components can query DNS (UDP/53) in kube-system namespace

### Component Policies

#### Cert-Manager (if enabled)
- **Policy**: `cert-manager-private`
- **Allows**:
  - Internal cert-manager communication within namespace
  - Outbound to security components for coordination
  - DNS queries
  - HTTPS (TCP/443) to external CAs for certificate validation

#### External Secrets (if enabled)
- **Policy**: `external-secrets-private`
- **Allows**:
  - Internal External Secrets communication within namespace
  - DNS queries
  - HTTPS (TCP/443) to secret backends (AWS Secrets Manager, Azure Key Vault, etc.)
  - Blocks access to EC2 metadata endpoint for security

#### Istio (if enabled)
- **Policy**: `istio-private`
- **Allows**:
  - Internal Istio control plane communication
  - Communication from namespaces with `istio-injection: enabled` label
  - DNS queries
  - Internal mesh communication

#### Application Namespace
- **Policy**: `app-allow-public`
- **Allows**:
  - Public ingress from ingress-nginx controller only
  - **Blocks**: Direct ingress from external sources (must go through ingress controller)

#### Database Namespace
- **Policy**: `database-private`
- **Allows**:
  - Ingress only from application namespace on TCP/5432 (PostgreSQL)
  - **Blocks**: All other traffic

#### Monitoring Namespace
- **Policy**: `monitoring-private`
- **Allows**:
  - Internal monitoring namespace communication for scraping
  - **Blocks**: External access to monitoring dashboards

#### Security Namespace
- **Policy**: `security-internal-only`
- **Allows**:
  - Internal security namespace communication only
  - **Blocks**: All external ingress

## Traffic Flow

```
External User
    ↓
Ingress Controller (ingress-nginx namespace) - Private
    ↓
Application Pod (app namespace) - Public HTTP entry point
    ↓
Database Pod (database namespace) - Private (TCP/5432)
    ↓
(Only from app namespace)

Security Components (cert-manager, external-secrets, istio)
    ↓
- Internal only (private)
- DNS queries to kube-system
- External APIs for secrets/certificates (HTTPS only)
```

## Configuration Variables

- `app_namespace_name`: Application namespace (default: "default")
- `database_namespace`: Database namespace (default: "database")
- `monitoring_namespace`: Monitoring namespace (default: "monitoring")
- `ingress_namespace`: Ingress controller namespace (default: "ingress-nginx")
- `enable_cert_manager`: Enable cert-manager policies
- `enable_external_secrets`: Enable external-secrets policies
- `enable_istio`: Enable istio policies
- `enable_monitoring`: Enable monitoring policies

## Namespace Labels Required

Ensure these labels are applied to namespaces for policies to work:

```yaml
metadata:
  labels:
    name: <namespace-name>
```

For Istio injection:
```yaml
metadata:
  labels:
    istio-injection: enabled
```

## Testing Network Policies

### Test default deny
```bash
kubectl run --image=busybox test-pod -it --rm -- sh
# This should timeout trying to reach other pods
wget -O- http://other-pod:8080
```

### Test allowed communication
```bash
# Test app to database
kubectl run --image=postgres:15 psql-test --rm -it \
  -n app \
  -- psql -h postgres-primary.database -p 5432 -U postgres
```

### Verify policies
```bash
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name> -n <namespace>
```

## Security Considerations

1. **Private Subnets**: All components except ingress are restricted to internal communication
2. **Public Application**: Application can only be accessed through ingress controller with explicit rules
3. **Database Protection**: Database only accepts connections from application namespace
4. **Monitoring Isolation**: Monitoring endpoints are not publicly accessible
5. **Secret Management**: External secrets can reach cloud providers but not EC2 metadata
6. **Certificate Management**: Cert-manager can reach external CAs for certificate validation

## Cleanup

To remove all network policies:
```bash
kubectl delete networkpolicy -A --all
```

To remove specific component policies:
```bash
kubectl delete networkpolicy cert-manager-private -n cert-manager
kubectl delete networkpolicy external-secrets-private -n external-secrets
kubectl delete networkpolicy istio-private -n istio-system
```
