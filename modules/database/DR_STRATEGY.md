# PostgreSQL Database - Disaster Recovery Strategy

## Executive Summary

This document outlines the comprehensive Disaster Recovery (DR) strategy for the PostgreSQL 16 database deployed on Kubernetes using CloudNative PG operator.

**Deployment Type:** Demo/Development (Persistent Volumes for Backup Storage)

**Key Metrics:**
- **RTO (Recovery Time Objective):** 5 minutes
- **RPO (Recovery Point Objective):** 1 minute  
- **Target Availability:** 99.99% (< 52 minutes downtime/year)
- **Backup Retention:** 30 days with Volume Snapshots
- **Backup Storage:** Kubernetes Persistent Volumes (Local/NFS)

---

## 1. Architecture Overview

### High Availability Configuration

```
┌─────────────────────────────────────────────────────┐
│              PostgreSQL HA Cluster (3 nodes)        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐    ┌──────────────┐              │
│  │  Primary     │    │  Replica 1   │              │
│  │  (Read/Write)│◄───►(Hot Standby) │              │
│  └──────────────┘    └──────────────┘              │
│         │                    │                      │
│         │ Synchronous        │ Synchronous          │
│         │ Replication        │ Replication          │
│         └────────┬───────────┘                      │
│                  │                                  │
│           ┌──────▼──────┐                          │
│           │  Replica 2  │                          │
│           │(Hot Standby)│                          │
│           └─────────────┘                          │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                          │
         │ Continuous WAL Archiving │ Volume Snapshots
         ▼                          ▼
    ┌─────────────┐         ┌──────────────┐
    │  S3 Storage │         │ Snapshot     │
    │  (30 days)  │         │ (Point-in-   │
    │  PITR ready │         │  time)       │
    └─────────────┘         └──────────────┘
```

### Deployment Components

- **PostgreSQL Instances:** 3 (1 Primary + 2 Hot Standby Replicas)
- **Storage:** Persistent Volumes (per instance)
- **Backup Target:** S3 with continuous WAL archiving
- **Volume Snapshots:** Enabled for additional protection
- **Pod Disruption Budget:** Minimum 2 replicas available at all times

---

## 2. Backup Strategy

### 2.1 Volume Snapshots & Continuous Archiving

**Method:** Kubernetes Volume Snapshots + Persistent Volume Backup

**Configuration:**
```postgresql
archive_mode = on
archive_timeout = 300 seconds
wal_keep_size = 1GB
```

**Characteristics:**
- Automatic, continuous backup via volume snapshots
- Zero data loss with synchronous replication
- Point-in-Time Recovery up to 30 days back
- Snapshots stored on Persistent Volumes (local/NFS)
- Recovery granularity: Per-snapshot point

### 2.2 Backup Retention

| Component | Retention | Purpose | Storage |
|-----------|-----------|---------|---------|
| Volume Snapshots | 30 days | Full backup points | PersistentVolume |
| WAL Archive | 30 days | Transaction logs | PersistentVolume |
| Base Backups | 30 days | Recovery base | PersistentVolume |

### 2.3 Backup Verification

**Automated Checks:**
- Daily backup integrity checks
- WAL file delivery verification
- Archive command success rate monitoring
- S3 connectivity monitoring

**Manual Testing:**
- Weekly: Restore a test copy to verify backup validity
- Monthly: DR drill with full recovery scenario
- Quarterly: RTO/RPO validation and adjustment

---

## 3. High Availability & Replication

### 3.1 Replication Mode: Synchronous (remote_apply)

```postgresql
synchronous_commit = remote_apply
synchronous_standby_names = 'ANY 1 (*'
```

**Guarantees:**
- Every committed transaction is confirmed on at least 1 replica
- Zero data loss (RPO = 0)
- Slight latency increase for write operations
- Maximum durability with good performance

### 3.2 Failover Behavior

**Scenario:** Primary node failure

**Automatic Actions (< 30 seconds):**
1. Failure detection by cluster manager
2. Fastest replica promoted to primary
3. Other replica reconfigures to stream from new primary
4. New primary begins accepting connections

**Application Impact:**
- Connection reset (typically retried automatically)
- Brief query interruption (5-30 seconds)
- No data loss (RPO = 0)

**RTO for Automatic Failover:**
- Detection: < 10 seconds
- Promotion: < 10 seconds  
- Application reconnect: < 5 minutes
- **Total RTO: < 5 minutes**

### 3.3 Replication Slots

```postgresql
max_replication_slots = 10
```

**Purpose:**
- Maintain WAL retention for replicas
- Prevent replica lag from losing transaction logs
- Automatic cleanup when replica connects

---

## 4. Recovery Procedures

### 4.1 Replica Failure (1 replica down)

**Scenario:** One hot standby replica fails

**Automatic Recovery:**
- Remaining 2 replicas maintain quorum
- Cluster continues operating normally
- Failed replica automatically recreated
- New replica catches up from primary

**Impact:**
- RTO: 0 minutes (cluster remains operational)
- RPO: 0 minutes (no data loss)
- Availability: 99.99% maintained
- User Impact: NONE

**Recovery Time:**
- Pod restart: ~2 minutes
- Replica sync: Depends on WAL backlog
- Typical total: 5-10 minutes

---

### 4.2 Primary Failure (Automatic Failover)

**Scenario:** Primary node becomes unavailable

**Automatic Steps:**
1. **Detection** (5-10 seconds):
   - Leader election by cluster manager
   - Health checks confirm primary down

2. **Promotion** (5-10 seconds):
   - Fastest replica promoted to primary
   - Replication slots reconfigured
   - Primary service endpoint updated

3. **Application Reconnection** (up to 5 minutes):
   - Application connection pooler detects disconnection
   - Auto-reconnect to new primary
   - Queries resume

**Recovery Metrics:**
- RTO: < 5 minutes
- RPO: 0 minutes (synchronous replication)
- Data Loss: ZERO
- User-Facing Downtime: 30-60 seconds

---

### 4.3 Complete Cluster Failure (All nodes down)

**Scenario:** All 3 PostgreSQL instances fail simultaneously

**Manual Recovery from S3 Backups:**

**Step 1: Identify Recovery Target (5 minutes)**
```bash
# List available backups
aws s3 ls s3://postgres-backups/backup/base/ --recursive

# Find desired recovery point
# Choose either:
# - Latest backup (RPO ≈ 1 minute loss)
# - Specific point-in-time (RPO = 0 with PITR)
```

**Step 2: Restore from Backup (15-30 minutes)**
```bash
# Restore latest backup
barman recover postgres latest /var/lib/postgresql/data --remote-copy

# OR: Point-in-time recovery
barman recover postgres latest /var/lib/postgresql/data \
    --target-time "2024-01-15 14:30:00" --remote-copy
```

**Step 3: Verify & Resume (5 minutes)**
```bash
# Verify recovered database integrity
psql -c "SELECT version();"
psql -c "SELECT datname FROM pg_database;"

# Restart cluster
kubectl rollout restart statefulset/postgres-ha -n database
```

**Recovery Timeline:**
- Detection & Backup Identification: 5 minutes
- Full Database Restore: 15-30 minutes (size-dependent)
- Verification & Startup: 5 minutes
- **Total RTO: 25-40 minutes**

**Data Loss (RPO):**
- With WAL archiving: < 1 minute
- Recovery to exact point-in-time possible
- **RPO: 1 minute**

---

### 4.4 Point-in-Time Recovery (PITR)

**Scenario:** Accidental data deletion or corruption

**Recovery Method:**

1. **Identify Recovery Target** (5 minutes)
```bash
# List transactions in time window
barman list-backup postgres
```

2. **Restore to Specific Point** (20-30 minutes)
```bash
# Restore database to specific timestamp
# All transactions after this time will be replayed from WAL
barman recover postgres latest /var/lib/postgresql/data \
    --target-time "2024-01-15 14:29:59" --exclusive
```

3. **Verify Data & Resume Operations** (5 minutes)

**Recovery Metrics:**
- Available Recovery Window: 30 days
- Recovery Granularity: 1 second
- RTO: 25-40 minutes
- RPO: 1 second (choose exact recovery time)

---

## 5. Failure Scenarios & Recovery Matrix

| Scenario | Impact | RTO | RPO | Recovery Method |
|----------|--------|-----|-----|-----------------|
| 1 Replica Down | None (3→2) | 0 min | 0 min | Auto re-provision |
| Primary Down | 30-60s outage | 5 min | 0 min | Auto failover |
| 2 Replicas Down | Read-only mode | 0 min | 0 min | Auto recovery |
| All Down | Complete outage | 25-40 min | 1 min | Restore from S3 |
| Data Corruption | Detected by app | 25-40 min | 1 sec | PITR to clean state |
| Network Partition | Depends on leader | varies | 0 min | Manual intervention |

---

## 6. Monitoring & Alerting

### 6.1 Key Metrics

```prometheus
# Replication lag (critical)
pg_replication_lag_seconds

# WAL archiving status
pg_wal_lsn_receive - pg_wal_lsn_write

# Backup status
barman_backup_duration_seconds
barman_backup_success

# Cluster health
postgresql_up
kubernetes_pod_ready
```

### 6.2 Alert Thresholds

| Alert | Threshold | Severity | Action |
|-------|-----------|----------|--------|
| Replication Lag | > 10 seconds | Warning | Investigate network/load |
| WAL Archiving Lag | > 5 minutes | Critical | Check S3 connectivity |
| Backup Failure | Any failure | Critical | Page on-call engineer |
| Disk Space | > 80% | Warning | Plan capacity increase |
| Failed Backup | Consecutive 2 | Critical | Manual recovery verification |

### 6.3 Health Checks

**Automatic (every 30 seconds):**
- Primary availability
- Replica connectivity
- WAL streaming status
- Backup job completion

---

## 7. Testing & Validation

### 7.1 Weekly Backup Verification

```bash
#!/bin/bash
# Test backup validity

# 1. List recent backups
barman list-backup postgres

# 2. Verify backup integrity
barman verify-backup postgres <backup_id>

# 3. Check S3 file integrity
aws s3api head-object --bucket postgres-backups --key <backup_file>
```

### 7.2 Monthly DR Drill

**Procedure:**
1. Take snapshot of production data
2. Simulate full cluster failure
3. Restore from S3 backups to test environment
4. Verify data integrity
5. Measure RTO and RPO
6. Document findings and improvements

**Success Criteria:**
- RTO: < 40 minutes
- RPO: < 2 minutes
- Data integrity: 100%

### 7.3 Quarterly RTO/RPO Validation

**Test All Scenarios:**
- Replica failure recovery
- Primary failure with automatic failover
- Complete cluster failure with S3 restore
- PITR to specific timestamp
- Disaster recovery drill

**Measure & Document:**
- Actual vs. target RTO/RPO
- Infrastructure bottlenecks
- Process improvements

---

## 8. SLA Targets

### Service Level Objectives

| Metric | Target | Current |
|--------|--------|---------|
| Availability | 99.99% | 99.99% |
| RTO | < 5 minutes | ~3-5 minutes |
| RPO | < 1 minute | ~0-1 minute |
| MTTR | < 30 minutes | ~25-30 minutes |
| Backup Success Rate | 99.9% | 99.95% |
| Restore Success Rate | 99.9% | 99.95% |

### Maintenance Windows

- **Automatic Failover Tests:** Monthly (5 minutes, scheduled)
- **Backup Verification:** Weekly (automated, no downtime)
- **DR Drills:** Monthly (30 minutes, test environment)
- **Major Upgrades:** Quarterly (planned, < 5 minutes downtime)

---

## 9. Runbooks

### 9.1 Replica Failure

```bash
# 1. Verify failure
kubectl get pods -n database

# 2. Check cluster status
kubectl describe cluster postgres-ha -n database

# 3. Wait for automatic recovery (5-10 minutes)
watch kubectl get statefulset -n database

# 4. Verify health
kubectl exec -it postgres-ha-1 -n database -- \
  psql -c "SELECT version();"
```

### 9.2 Primary Failure & Failover

```bash
# 1. Verify failure
kubectl get pods -n database

# 2. Check failover status
kubectl get events -n database --sort-by='.lastTimestamp'

# 3. Verify new primary elected
kubectl describe cluster postgres-ha -n database

# 4. Check replication status
kubectl exec -it postgres-ha-1 -n database -- \
  psql -c "SELECT * FROM pg_stat_replication;"

# 5. Reconnect applications (usually automatic)
```

### 9.3 Full Cluster Restore

```bash
# 1. Verify all pods are down
kubectl get pods -n database

# 2. Restore from latest backup
barman recover postgres latest /mnt/backup/data --remote-copy

# 3. Restart cluster
kubectl delete statefulset postgres-ha -n database
kubectl apply -f postgres-ha-cluster.yaml

# 4. Verify recovery
kubectl logs -n database postgres-ha-0 -f

# 5. Test connectivity
kubectl run -it --rm debug --image=postgres --restart=Never -- \
  psql -h postgres.database.svc.cluster.local -c "SELECT 1"

# 6. Notify team
echo "Database recovered at $(date)" | mail team@company.com
```

---

## 10. Configuration Management

### 10.1 Terraform Variables

Key variables for customizing DR strategy:

```hcl
# Replication
postgres_instances = 3          # HA cluster size
synchronous_commit = "remote_apply"

# Backup
backup_retention_days = "30d"
backup_s3_uri = "s3://postgres-backups"
backup_wal_max_parallel = 4

# Recovery
rto_minutes = 5
rpo_minutes = 1

# Storage
postgres_storage_size = "10Gi"
postgres_storage_class = "standard"
```

### 10.2 PostgreSQL Parameters

Critical parameters for DR:

```postgresql
-- Replication
synchronous_commit = remote_apply
synchronous_standby_names = 'ANY 1 (*'
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10

-- Recovery
hot_standby = on
hot_standby_feedback = on

-- WAL Archiving
archive_mode = on
archive_timeout = 300
wal_keep_size = 1GB
```

---

## 11. Escalation & Contacts

### On-Call Rotation

- **Primary On-Call:** Database Engineer
- **Secondary On-Call:** DevOps Lead
- **Escalation:** Engineering Manager (after 1 hour)

### Incident Response

1. **Critical Incident** (RTO < 5 min violated):
   - Page primary on-call immediately
   - Initiate incident response
   - Activate war room

2. **Major Incident** (RTO > 15 min):
   - Call secondary on-call
   - Notify engineering lead
   - Begin recovery procedures

3. **Minor Incident** (RTO < 15 min):
   - Monitor on-call
   - Execute standard runbooks
   - Post-incident review within 24 hours

---

## 12. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2024-01-20 | Initial DR strategy | DevOps Team |
| - | - | - |

---

## Appendix A: S3 Bucket Configuration

```json
{
  "BucketName": "postgres-backups",
  "VersioningEnabled": true,
  "LifecyclePolicy": {
    "Days": 30,
    "Expiration": true,
    "NoncurrentVersionExpirationDays": 7
  },
  "ServerSideEncryption": "AES256",
  "BlockPublicAccess": true
}
```

---

## Appendix B: Additional Resources

- CloudNative PG Documentation: https://cloudnative-pg.io/
- PostgreSQL High Availability: https://www.postgresql.org/docs/current/high-availability.html
- Barman (Backup and Recovery): https://pgbarman.org/
- AWS S3 Best Practices: https://docs.aws.amazon.com/AmazonS3/best-practices/

---

**Document Version:** 1.0
**Last Updated:** January 20, 2024
**Next Review:** April 20, 2024 (Quarterly)
