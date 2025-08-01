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
task talos:gen-secrets                       # Generate secrets and push to 1Password
task talos:apply-config NODE=<ip>            # Apply to all nodes
task talos:bootstrap NODE=<ip>               # Bootstrap first control plane
task bootstrap:apps                          # Deploy Kubernetes apps

# Secret management (simplified workflow)
task talos:pull-secrets                      # Pull secrets from 1Password
task talos:push-secrets                      # Push local secrets to 1Password
task talos:backup-secrets                    # Backup current secrets
task talos:list-backups                      # List available backups
task talos:restore-secrets BACKUP=<timestamp> # Restore from backup

# Kubernetes operations
task kubernetes:browse-pvc CLAIM=<pvc-name>    # Debug PVC by mounting to temp pod
task kubernetes:node-shell NODE=<node>         # Shell into cluster node
task kubernetes:sync-secrets                   # Force sync all ExternalSecrets
task kubernetes:cleanse-pods                   # Clean up failed/pending pods

# Node management
task talos:upgrade-node NODE=<ip>              # Upgrade single Talos node
task talos:upgrade-k8s                         # Upgrade entire Kubernetes cluster
task talos:reboot-node NODE=<ip>               # Reboot single node
task talos:remove-node NODE=<name>              # Remove node from cluster completely

# Backup operations
task volsync:snapshot APP=<name>               # Create app snapshot
task volsync:restore APP=<name> PREVIOUS=<snapshot>  # Restore from backup

# External access setup
task setup-cloudflare-tunnel                  # Configure tunnel for external service access

# Secret management
task bootstrap-media-secrets                  # Bootstrap API keys for media services
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
talos/
├── static-configs/ # Node-specific configurations (temporary approach)
├── node-mapping.yaml # Source of truth for active nodes
└── talosconfig    # Generated cluster access config
scripts/          # Automation scripts
```

**Note**: Currently using static per-node YAML configs due to diverse hardware (EQ12, P520 workstation, etc.). Originally designed with minijinja templates, but mixed hardware made template maintenance complex. **Planning return to template-based approach** once hardware is standardized to reduce maintenance overhead of shared settings updates.

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
- **CONTROL_PLANE_ENDPOINT**: `https://homeops.hypyr.space:6443` (Points to kube-vip LoadBalancer: 10.0.48.55)
- **TALOS_ENDPOINTS**: `10.0.5.215,10.0.5.220,10.0.5.118`
- **TALOS_NODES**: Dynamically extracted from `talos/node-mapping.yaml` (currently: 3 nodes)
- **OP_VAULT**: `homelab` (1Password vault)

### Node Mapping
- **home01** (10.0.5.215) - EQ12 with dual Ethernet bond
- **home02** (10.0.5.220) - EQ12 with dual Ethernet bond  
- **home04** (10.0.5.118) - P520 workstation with Ethernet bond

**Note**: home03 has been removed from cluster rotation due to hardware issues (NVMe drive failures). Node configuration preserved for potential future reintegration.

### Networking
- **CNI**: Cilium with eBPF
- **LoadBalancer**: Cilium L2/L3 hybrid mode
- **DNS**: ExternalDNS syncs to UniFi (internal) and Cloudflare (external)
- **Ingress**: Cilium Gateway API with internal/external gateways
- **VPN**: Tailscale for remote access

## Storage & Backups

### Storage Classes
- **Rook Ceph**: Distributed block storage for persistent volumes
- **OpenEBS**: Local hostpath storage using `/var/mnt/local-storage` (actual Talos user volume mount point)
- **NFS**: External media storage from TrueNAS

**Important**: OpenEBS uses `/var/mnt/local-storage` because Talos UserVolumeConfig mounts user volumes there, but doesn't automatically create the expected bind mount to `/var/local-storage`. All nodes show user volumes mounted at `/var/mnt/local-storage`.

### Backup Strategy
- **VolSync**: Automated PVC backups using Restic
- **Destinations**: S3-compatible storage (SeaweedFS on Synology NAS)
- **Encryption**: Restic encryption for all backup data

## Secret Management

### 1Password Integration
- **Vault**: `homelab`
- **Connect**: OnePassword Connect pods in `external-secrets` namespace
- **ClusterSecretStore**: `onepassword` store for secret fetching
- **ExternalSecrets**: Convert 1Password items to Kubernetes secrets

### Talos Secret Workflow
The cluster uses 1Password as the source of truth for Talos certificates and secrets:

```bash
# Pull secrets from 1Password (matches what nodes are using)
task talos:pull-secrets

# Push local secrets to 1Password (updates what nodes will use on next apply)
task talos:push-secrets

# Generate brand new secrets and push to 1Password
task talos:gen-secrets

# Backup current secrets before making changes
task talos:backup-secrets

# List available backups
task talos:list-backups

# Restore from backup
task talos:restore-secrets BACKUP=20250730-114330
```

### Secret Troubleshooting

**Certificate Mismatch Issues:**
- If bootstrap fails with certificate errors, local secrets don't match 1Password
- Solution: `task talos:pull-secrets` to sync from 1Password
- Or revert 1Password item in GUI, then `task talos:pull-secrets`

**1Password Connect Issues:**
- **ALWAYS use task commands first**: `task kubernetes:sync-secrets` - auto-detects and fixes 1Password Connect issues
- For manual checking: `kubectl get clustersecretstore onepassword -o yaml`
- The sync-secrets task automatically recreates the 1Password secret if needed

**Secret Sync Issues:**
```bash
# Force sync all secrets (preferred method - auto-fixes 1Password Connect)
task kubernetes:sync-secrets

# Check specific ExternalSecret status
kubectl describe externalsecret <name> -n <namespace>
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

## Common Patterns
- Always check ExternalSecret status when secrets aren't syncing
- Use `task kubernetes:sync-secrets` to force refresh all secrets
- Monitor Flux reconciliation with `flux get kustomizations`
- Check Talos node health with `talosctl get members`

## Flux Git Reconciliation

When you make changes to YAML files in the repository, Flux needs to detect and apply them. Use these commands to force Flux to reconcile from Git:

```bash
# Force reconcile the Git source (picks up file changes from repository)
flux reconcile source git flux-system

# Force reconcile specific Kustomizations (applies changes to cluster)
flux reconcile kustomization cluster-apps
flux reconcile kustomization cluster-meta

# Force reconcile specific application (useful after changing a single app)
flux reconcile kustomization <app-name> -n <namespace>

# Check Flux system status
flux get sources git
flux get kustomizations
flux get helmreleases -A

# Resume suspended resources
flux resume kustomization <name>
flux resume helmrelease <name> -n <namespace>
```

**Common workflow after making file changes:**
1. Commit and push changes to Git
2. `flux reconcile source git flux-system` (force Git sync)
3. `flux reconcile kustomization cluster-apps` (apply changes)
4. Check status with `kubectl get pods -A` or `flux get kustomizations`

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

### Documentation Guidelines
- **Keep troubleshooting logs** in the `docs/` folder for future reference
- **Target audience**: Users forking this repo for their own homelabs (Docker-familiar, K8s-new)
- **Document solutions** with context for common issues encountered
- **Include commands and configuration examples** for reproducibility
- **Key docs**: `docs/SETUP-GUIDE.md` (main setup), `docs/1PASSWORD-SETUP.md` (secrets), `docs/CLUSTER-TROUBLESHOOTING.md` (issues)

### Task Command Usage
- **ALWAYS prefer task commands** over raw kubectl/talosctl commands when available
- **Use `task --list`** to discover available commands before writing custom solutions
- **Task commands handle prerequisites** and provide consistent error handling
- **Examples of when to use tasks:**
  - `task kubernetes:sync-secrets` instead of manual ExternalSecret annotations
  - `task talos:pull-secrets` instead of manual 1Password/secrets.yaml management
  - `task kubernetes:browse-pvc CLAIM=name` instead of complex kubectl commands
  - `task volsync:snapshot APP=name` instead of manual VolSync operations
- **Document new solutions as task commands** when they solve recurring problems

### Talos Cluster Management
**Always prefer task commands for common operations:**
- **Node removal**: `task talos:remove-node NODE=<name>` - Handles Kubernetes, etcd, and config cleanup
- **Node addition**: Add to `talos/node-mapping.yaml`, then apply configs normally
- **Cluster health**: `task talos:generate-config-healthy` - Auto-detects healthy nodes

**When no specific task command exists, use proper `talosctl` commands:**
- **Cluster health**: `talosctl etcd members` and `talosctl etcd status`
- **Storage management**: `talosctl wipe disk <device>` for cleaning storage devices
- **Node maintenance**: `talosctl --nodes <node> reset --reboot=false` for maintenance mode
- **NEVER use kubectl** for Talos-level operations (node management, etcd, storage)

**Source of Truth**: All node management uses `talos/node-mapping.yaml` as the authoritative node list.
- **Check available commands**: `talosctl <command> --help` to explore options

## External Dependencies

- **1Password**: Secret management
- **Cloudflare**: DNS management
- **GitHub**: Repository hosting and CI/CD
- **UniFi**: Network infrastructure
- **Synology NAS**: S3-compatible storage (SeaweedFS) for backups
- **TrueNAS**: Media file storage