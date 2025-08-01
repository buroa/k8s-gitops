# Home-Ops Kubernetes Cluster Setup Guide

*For users familiar with Docker but new to Kubernetes*

## Overview

This guide helps you deploy a GitOps-managed Kubernetes cluster using:
- **Talos Linux** - Immutable OS for Kubernetes nodes
- **Flux** - GitOps for automatic application deployment 
- **1Password** - Secret management
- **Task** - Automation commands

## Prerequisites

- 3+ nodes running Talos Linux
- 1Password CLI (`op`) installed and signed in
- Tools installed: `task`, `talosctl`, `kubectl` (use `task workstation:brew` to install)

## Quick Start

### 1. Generate Cluster Secrets
```bash
# Generate new secrets and store in 1Password
task talos:gen-secrets
```

### 2. Apply Node Configurations
```bash
# Apply configs to each node (use your actual node IPs)
task talos:apply-config NODE=10.0.5.215 INSECURE=true
task talos:apply-config NODE=10.0.5.220 INSECURE=true  
task talos:apply-config NODE=10.0.5.100 INSECURE=true
```

### 3. Bootstrap Cluster
```bash
# Bootstrap on any control plane node
task talos:bootstrap NODE=10.0.5.215

# Deploy applications with GitOps
task bootstrap:apps
```

**That's it!** Your cluster is now running with all applications automatically deployed via Flux.

## Understanding What Just Happened

If you're coming from Docker, here's how this relates:

- **Talos** = Like a minimal Linux distro optimized for containers
- **Kubernetes** = Like Docker Compose but for multiple servers
- **Flux** = Automatically deploys apps when you change YAML files in Git
- **1Password Connect** = Safely injects secrets into containers

## Common Operations

### Check Cluster Status
```bash
# See all nodes
kubectl get nodes

# See all running applications  
kubectl get pods -A

# Check GitOps status
flux get kustomizations
```

### Fix Secret Issues
```bash
# Auto-fixes 1Password Connect and syncs all secrets
task kubernetes:sync-secrets
```

### Browse Storage
```bash
# Mount a persistent volume to debug storage issues
task kubernetes:browse-pvc CLAIM=pvc-name
```

### Backup/Restore
```bash
# Create snapshot of an application's data
task volsync:snapshot APP=plex

# Restore from backup  
task volsync:restore APP=plex PREVIOUS=snapshot-name
```

*Note: Backups go to S3-compatible storage (SeaweedFS). You may need to adjust S3 endpoints/credentials for your setup.*

## Troubleshooting

### Secrets Not Working
**Symptom**: Apps showing "secret not found" errors
**Solution**: `task kubernetes:sync-secrets` - This auto-detects and fixes 1Password Connect issues

### Apps Not Deploying  
**Symptom**: Pods stuck in "Pending" or "ImagePullBackOff"
**Check**: `kubectl describe pod <pod-name> -n <namespace>`
**Common fixes**:
- Storage issues: `task kubernetes:browse-pvc CLAIM=<name>`
- Secret issues: `task kubernetes:sync-secrets`

### Node Issues
**Symptom**: Node showing "NotReady" 
**Check**: `kubectl describe node <node-name>`
**Solution**: Often network or storage related - see CLUSTER-TROUBLESHOOTING.md

## Key Files

- `kubernetes/` - All your applications defined as code
- `talos/static-configs/` - Node configurations (currently static due to mixed hardware)
- `bootstrap/` - Initial cluster setup
- `CLAUDE.md` - Detailed command reference

**Note on Node Configurations**: This setup currently uses static YAML configs per node due to diverse hardware types (EQ12, P520 workstation, etc.). The original design used minijinja templates for dynamic generation, but maintaining templates for mixed hardware became complex. **Future plans include returning to template-based configs** once the hardware is standardized, as static configs create maintenance overhead when updating shared settings like certificate SANs.

## Next Steps

1. **Customize applications**: Edit YAML files in `kubernetes/apps/`
2. **Add secrets**: Store API keys in 1Password vault "homelab"
3. **Monitor**: Visit your cluster's status page at https://your-domain/status

The beauty of GitOps is that any changes you make to the `kubernetes/` folder will automatically deploy to your cluster within minutes!