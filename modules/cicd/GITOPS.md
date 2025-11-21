# GitOps with ArgoCD

This module deploys ArgoCD for declarative continuous deployment using GitOps principles.

## Architecture

### GitOps Workflow

```
GitHub Repository (Source of Truth)
    ↓
ArgoCD (Continuous Reconciliation)
    ↓
Kubernetes Cluster (Desired State)
```

## Features

- **Declarative Configuration**: All application state is defined in Git
- **Continuous Reconciliation**: ArgoCD automatically syncs cluster state with Git
- **Automated Sync**: Applications automatically sync with Git commits (if enabled)
- **Self-Healing**: ArgoCD detects and corrects drift from desired state
- **Multi-Application Support**: Deploy multiple applications from single repository
- **Helm Integration**: Supports Helm charts for templating

## Deployment

### Prerequisites

- Kubernetes cluster running
- Git repository with application manifests
- Terraform configured with Kubernetes provider

### Variables

```hcl
enable_cicd              = true
argocd_namespace         = "argocd"
git_repository_url       = "https://github.com/daucuong/devops-assessment.git"
git_repository_branch    = "main"
git_repository_path      = "k8s"
argocd_sync_policy       = "automated"
argocd_auto_prune        = true
argocd_self_heal         = true
```

## Applications

### 1. Echo Server (Application)

- **Name**: echo-server
- **Source**: `https://github.com/daucuong/devops-assessment.git/k8s`
- **Destination**: `application` namespace
- **Sync Policy**: Automated
- **Auto-Prune**: Enabled
- **Self-Heal**: Enabled

### 2. PostgreSQL HA (Database)

- **Name**: postgres-ha
- **Source**: `https://github.com/daucuong/devops-assessment.git/k8s/database`
- **Destination**: `database` namespace
- **Sync Policy**: Manual
- **Auto-Prune**: Disabled

## Access ArgoCD UI

### Port-Forward

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Open browser: `https://localhost:8080`

### Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### Login

```bash
Username: admin
Password: [from above command]
```

### Change Admin Password

```bash
argocd account update-password \
  --account admin \
  --new-password <new-password>
```

## Repository Structure

Expected structure in Git repository:

```
devops-assessment/
├── k8s/
│   ├── values.yaml          (Helm values for app)
│   ├── Chart.yaml           (Helm chart metadata)
│   └── templates/           (Helm templates)
├── k8s/database/
│   ├── values.yaml
│   ├── Chart.yaml
│   └── templates/
└── README.md
```

## Sync Status

### Check Application Status

```bash
# Get all applications
kubectl get applications -n argocd

# Get detailed status
kubectl describe application echo-server -n argocd

# Watch sync progress
kubectl -n argocd get app -w
```

### Manual Sync

```bash
# Using kubectl
kubectl patch application echo-server -n argocd -p \
  '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":""}}}' \
  --type merge

# Or using ArgoCD CLI
argocd app sync echo-server
```

## Sync Policy

### Automated Sync
- Application automatically syncs when changes are detected in Git
- Includes auto-prune to remove resources deleted from Git
- Includes self-heal to detect and correct drift

### Manual Sync
- Administrator must manually trigger sync
- Useful for production applications requiring approval

## GitOps Best Practices

1. **Single Source of Truth**: All configuration in Git
2. **Declarative**: Describe desired state, not steps
3. **Versioned**: All changes tracked in Git history
4. **Reviewable**: Pull requests for all changes
5. **Observable**: Full visibility into deployment status

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl describe application echo-server -n argocd

# Check ArgoCD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Git Repository Not Found

```bash
# Check git credentials secret
kubectl get secrets -n argocd
kubectl describe secret git-credentials -n argocd
```

### Sync Errors

```bash
# Check application conditions
kubectl get application echo-server -n argocd -o yaml

# Check deployed resources
kubectl get all -n application
```

## Network Policy Impact

ArgoCD requires network access to:
- Kubernetes API server
- Git repositories (HTTPS)
- Application namespaces (for deployment)

Update network policies to allow:
```yaml
# ArgoCD egress policy
argocd-server → Kubernetes API (TCP/443)
argocd-server → Git repositories (TCP/443)
argocd-server → Application namespaces (TCP/any)
```

## Cleanup

```bash
# Delete ArgoCD
terraform destroy -target=module.cicd

# Or manually
kubectl delete namespace argocd
```
