# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a home-ops GitOps repository managing a 3-node Talos Linux Kubernetes cluster with Flux CD. The cluster runs media applications, home automation, monitoring, and networking services with secrets managed by 1Password.

## Essential Commands

### Cluster Operations
```bash
# List all tasks
task --list

# Bootstrap the cluster from scratch
task talos:gen-secrets
task talos:apply-config NODE=<ip>
task talos:bootstrap NODE=<ip>
task bootstrap:apps

# Kubernetes operations
task kubernetes:browse-pvc CLAIM=<pvc-name>    # Debug PVC by mounting to temp pod
task kubernetes:node-shell NODE=<node>         # Shell into cluster node
task kubernetes:sync-secrets                   # Force sync all ExternalSecrets
task kubernetes:cleanse-pods                   # Clean up failed/pending pods

# Node management
task talos:upgrade-node NODE=<ip>              # Upgrade single Talos node
task talos:upgrade-k8s                         # Upgrade entire Kubernetes cluster
task talos:reboot-node NODE=<ip>               # Reboot single node

# Backup operations
task volsync:snapshot APP=<name>               # Create app snapshot
task volsync:restore APP=<name> PREVIOUS=<snapshot>  # Restore from backup
```

### Development Environment
```bash
# Install required tools and dependencies
task workstation:brew                          # Install Homebrew packages
task workstation:krew                          # Install kubectl plugins
```

## Architecture & Key Concepts

### GitOps Structure
- **Flux**: Manages cluster state from Git repository
- **HelmReleases**: Deploy applications via Helm charts
- **Kustomizations**: Define dependencies between applications
- **ExternalSecrets**: Pull secrets from 1Password vault "homelab"

### Directory Structure
```
kubernetes/
├── apps/           # Applications grouped by namespace
│   ├── cert-manager/
│   ├── external-secrets/
│   ├── flux-system/
│   ├── kube-system/
│   ├── media/      # Plex, Sonarr, Radarr, etc.
│   ├── networking/
│   └── observability/
├── components/     # Reusable kustomize components
└── flux/          # Flux system configuration

bootstrap/         # Initial cluster setup
talos/            # Talos node configurations
scripts/          # Automation scripts
```

### Application Deployment Pattern
Each app follows this structure:
- `ks.yaml` - Flux Kustomization with dependencies
- `app/helmrelease.yaml` - Helm chart configuration
- `app/externalsecret.yaml` - 1Password secret integration
- `app/kustomization.yaml` - Resource bundling

### Dependencies & Bootstrapping
Applications have explicit dependencies managed by Flux:
1. **Core**: Talos → Cilium → CoreDNS → Spegel
2. **Security**: cert-manager → external-secrets
3. **Applications**: Depend on core and security layers

## Cluster Configuration

### Key Variables (Taskfile.yaml)
- **CONTROL_PLANE_ENDPOINT**: `https://homeops.hypyr.space:6443`
- **TALOS_ENDPOINTS**: `homeops.hypyr.space`
- **TALOS_NODES**: `10.0.5.215,10.0.5.220,10.0.5.100`
- **OP_VAULT**: `homelab` (1Password vault)

### Node Mapping
- **home01** (10.0.5.215) - EQ12 with dual Ethernet bond
- **home02** (10.0.5.220) - EQ12 with dual Ethernet bond  
- **home03** (10.0.5.100) - NUC7 with single Ethernet

### Networking
- **CNI**: Cilium with eBPF
- **LoadBalancer**: Cilium L2/L3 hybrid mode
- **DNS**: ExternalDNS syncs to UniFi (internal) and Cloudflare (external)
- **Ingress**: Cilium Gateway API with internal/external gateways
- **VPN**: Tailscale for remote access

## Storage & Backups

### Storage Classes
- **Rook Ceph**: Distributed block storage for persistent volumes
- **OpenEBS**: Local storage for specific workloads
- **NFS**: External media storage from TrueNAS

### Backup Strategy
- **VolSync**: Automated PVC backups using Restic
- **Destinations**: Both Cloudflare R2 and local S3 (SeaweedFS)
- **Encryption**: Restic encryption for all backup data

## Secret Management

### 1Password Integration
- **Vault**: `homelab`
- **Connect**: OnePassword Connect pods in `external-secrets` namespace
- **ClusterSecretStore**: `onepassword` store for secret fetching
- **ExternalSecrets**: Convert 1Password items to Kubernetes secrets

### Common Secret Troubleshooting
```bash
# Check ExternalSecret status
kubectl describe externalsecret <name> -n <namespace>

# Verify 1Password connection
kubectl get clustersecretstore onepassword -o yaml

# Force secret sync
kubectl annotate externalsecrets --all external-secrets.io/force-sync=$(date +%s) -A
```

## Media Stack

### Core Applications
- **Plex**: Media server
- **Sonarr/Radarr**: TV/Movie management
- **qBittorrent**: Download client
- **Prowlarr**: Indexer aggregation
- **Overseerr**: Media requests

### Configuration Notes
- All media apps use NFS storage from TrueNAS
- API keys stored in 1Password and synced via ExternalSecrets
- Apps communicate via cluster DNS

## Monitoring & Observability

### Stack Components
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **Alloy**: Observability pipeline
- **Alertmanager**: Alert routing to Pushover

### Health Checks
- Status page: https://status.hypyr.space
- Badge endpoints via Kromgo
- Gatus for uptime monitoring

## Known Issues & Solutions

### OnePassword Connect Issue (FIXED Permanently)
**Problem**: OnePassword Connect credentials triple base64 encoded during bootstrap
- **Symptoms**: Sync container error: `"illegal base64 data at input byte 0"`
- **Root Cause**: 1Password CLI returns pre-encoded credentials, but `stringData` re-encodes them 
- **Solution**: **PERMANENT** - Modified bootstrap template to use `data` instead of `stringData`
- **Location**: `bootstrap/secrets.yaml.tpl` lines 18-19
- **Fix Details**:
  - Use `data:` for credentials (prevents double encoding)
  - Keep `stringData:` for token (plain text)
  - Added clear documentation for future removal when 1Password fixes CLI behavior
- **Impact**: ExternalSecrets sync properly, bootstrap process creates correct secret format
- **Dependencies**: Health checks added during `onepassword-stores` → `onepassword-store` rename now work correctly

### Common Patterns
- Always check ExternalSecret status when secrets aren't syncing
- Use `task kubernetes:sync-secrets` to force refresh all secrets
- Monitor Flux reconciliation with `flux get kustomizations`
- Check Talos node health with `talosctl get members`

## Development Workflow

### Feature Branch Strategy
- **Always** create focused feature branches for changes: `git checkout -b feat/description`
- **Never** commit directly to `main` branch
- **Create focused PRs** - one feature/fix per PR for easier review and rollback
- **Branch naming**: `feat/`, `fix/`, `chore/`, `docs/` prefixes

### Workflow Steps
1. **Create feature branch** from main: `git checkout -b feat/your-feature`
2. **Add feature to TODO.md** under "In Progress" section with task breakdown
3. **Make changes** to YAML files in appropriate directory
4. **Update TODO.md** as tasks are completed (mark with [x])
5. **Commit changes** with descriptive messages
6. **Push branch** and create PR to main
7. **Move completed feature to "Completed" section** in TODO.md after merge
8. **Monitor deployment** after merge with `kubectl get pods -A`
9. **Check logs** if issues occur: `kubectl logs -n <namespace> <pod>`
10. **Use task commands** for common operations

### Project TODO Management
- **Always maintain** `TODO.md` at project root with current work status
- **Track features** with task breakdowns under "In Progress"
- **Move completed work** to "Completed" section after successful deployment
- **Use checkboxes** `[ ]` and `[x]` to track individual task progress

## External Dependencies

- **1Password**: Secret management
- **Cloudflare**: DNS and R2 storage
- **GitHub**: Repository hosting and CI/CD
- **UniFi**: Network infrastructure
- **TrueNAS**: Media file storage