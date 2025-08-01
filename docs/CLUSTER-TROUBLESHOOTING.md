# Cluster Troubleshooting Guide

This document tracks common issues encountered during Talos cluster setup and their solutions.

## Issue: Name Resolver Errors After Node Reset

**Date**: 2025-07-31
**Status**: In Progress

### Problem
After resetting nodes to maintenance mode and reapplying configurations, encountering:
```
rpc error: code = Unavailable desc = name resolver error: produced zero addresses
```

### Investigation Steps

1. **Node Status**: All nodes (home01-home04) have kubelet running and healthy
2. **Disk Configuration**: All nodes have proper EPHEMERAL and user volume configurations
3. **Network**: Individual node connectivity works with explicit IP addresses

### Current Configuration Status
- **Home01**: 107GB EPHEMERAL, 392GB user storage ✅
- **Home02**: 54GB EPHEMERAL, 425GB user storage ✅  
- **Home03**: 54GB EPHEMERAL, 65GB user storage ✅
- **Home04**: 1TB EPHEMERAL, 1TB user storage ✅

### Potential Causes
- Talosconfig endpoint configuration issues
- Cluster bootstrap not completed
- etcd cluster not formed properly
- DNS/hostname resolution problems

### Root Cause Identified ✅
**Issue**: CNI (Container Network Interface) not initialized
- All nodes show: `NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized`
- Kubernetes API server is running on all nodes
- etcd cluster is healthy (3/4 nodes - home03 has connectivity issues)
- Cluster is ready for CNI deployment

### Solutions Attempted
- [x] Fix talosconfig endpoint format ✅
- [x] Check etcd cluster status ✅ (3/4 healthy)
- [x] Verify cluster bootstrap completion ✅ 
- [x] Check Kubernetes API server status ✅ (Running)
- [ ] Deploy CNI (Cilium) via bootstrap process

### Bootstrap COMPLETED Successfully! ✅
**Status**: `task bootstrap:apps` completed without timeout
- **Nodes**: 3/4 Ready ✅
- **Running Pods**: 68 pods successfully running ✅
- **Core Applications**: Deployed via Flux ✅

### What This Means for Your Homelab
If you're experiencing bootstrap timeouts, this successful deployment shows:
- **Disk Configuration Matters**: Adequate EPHEMERAL storage (50GB+) prevents resource constraints
- **Network Connectivity**: 3/4 nodes sufficient for cluster operation
- **Kubelet Health**: All services running properly enables smooth bootstrap

### Outstanding Issues for Your Environment
1. **Node Connectivity**: One node unreachable - check physical network/power
2. **1Password Secrets**: ExternalSecrets showing sync errors - verify vault access
3. **Workload Scheduling**: Some pods pending on unreachable node (expected behavior)

### Key Commands That Helped
```bash
# Fix disk configurations before bootstrap
task talos:reset-node-maintenance NODE=<node-ip>
task talos:apply-config NODE=<node> INSECURE=true

# Monitor bootstrap progress  
kubectl get nodes
kubectl get pods -A | grep -v Running
kubectl get helmreleases -A

# Fix 1Password Connect and ExternalSecrets
task kubernetes:sync-secrets  # Auto-detects and fixes 1Password issues
```

---

## Issue: 1Password Connect Authentication Failure

**Date**: 2025-07-31  
**Status**: Active Issue

### Problem
ExternalSecrets showing `SecretSyncedError` with 1Password Connect errors:
- ClusterSecretStore: `status 401: Invalid bearer token`
- Connect API logs: `could not parse JWT, compact JWS format must have three parts`

### Root Cause
The Kubernetes secret contains **template strings** instead of actual values:
```bash
kubectl get secret onepassword-secret -n external-secrets -o jsonpath='{.data.token}' | base64 -d
# Returns: $(op item get 1password --field OP_CONNECT_TOKEN --vault homelab --reveal)
# Should return: actual JWT token
```

**Technical Background**: 1Password Connect sync container requires double base64 encoding for credentials (see [GitHub issue #202](https://github.com/1Password/connect-helm-charts/issues/202)). The automated `op inject` template processing previously failed due to encoding mismatches and token/server misalignment.

### Solution for Homelab Users ✅ RESOLVED
The automated secret creation via `op inject` doesn't work in Kubernetes. Manual secret creation required:

```bash
# 1. Get proper values from 1Password  
OP_CREDENTIALS=$(op item get 1password --field OP_CREDENTIALS_JSON --vault homelab --reveal | base64 -d | sed 's/""/"/g' | base64 -w 0)

# 2. Create token with correct server ID (not server name)
SERVER_ID=$(op connect server list | grep homelab | awk '{print $1}')
OP_TOKEN=$(op connect token create "k8s-cluster-$(date +%s)" --server "$SERVER_ID" --vault homelab)

# 3. Delete existing broken secret
kubectl delete secret onepassword-secret -n external-secrets

# 4. Create proper secret with actual values
kubectl create secret generic onepassword-secret \
  --from-literal=1password-credentials.json="$OP_CREDENTIALS" \
  --from-literal=token="$OP_TOKEN" \
  -n external-secrets

# 5. Restart 1Password Connect pods
kubectl delete pod -l app.kubernetes.io/name=onepassword -n external-secrets
```

**Resolution Status**: FULLY AUTOMATED ✅
- ClusterSecretStore shows "store validated" 
- ExternalSecrets syncing successfully
- Authentication errors resolved
- Connect pods healthy and responding
- **Now works with automated `op inject` process!**

**Key Fixes**: 
1. Using Connect server ID instead of server name for token creation
2. Storing properly formatted credentials in 1Password for automation
3. Updated secrets.yaml.tpl to use direct field values (no re-encoding)

**For Future Deployments**: 
- **Automated**: Run `task bootstrap:apps` (incorporates the 1Password fix)
- **Manual**: Run `cat bootstrap/secrets.yaml.tpl | op inject | kubectl apply -f -`
- **Troubleshooting**: Run `task kubernetes:sync-secrets` (auto-detects and fixes issues) ✅

---

## Issue: BGP Not Advertising Gateway LoadBalancer IPs

**Status**: RESOLVED ✅

### Problem Description
BGP working for cluster endpoint but not advertising Gateway LoadBalancer IPs. Router shows incomplete BGP routes.

### Common Symptoms
- Gateway services not accessible from outside cluster
- DNS records for gateway domains not resolving
- BGP advertising fewer IPs than expected to your router
- External traffic can't reach ingress services

### Understanding the Architecture
This setup uses:
- **Cilium CNI** with BGP for LoadBalancer advertisement
- **Gateway API** resources that request specific LoadBalancer IPs
- **External-DNS** that automatically creates DNS records for gateways
- **Flux GitOps** managing the deployment dependencies

The critical dependency chain: `Cilium → Gateway resources → LoadBalancer services → BGP advertisement`

### Root Cause Pattern
**Key insight**: Network routing issues are often actually Kubernetes resource deployment failures.

In this case, a failed Cilium HelmRelease prevented Gateway resources from being deployed, which meant:
1. No LoadBalancer services requesting the gateway IPs
2. BGP had nothing to advertise beyond the cluster endpoint
3. External-DNS had no services to create DNS records for

### Diagnostic Approach for Your Setup

**Start with resource existence, not network configuration:**

```bash
# 1. Do your Gateway resources exist?
kubectl get gateway -A
# If empty, investigate your CNI deployment

# 2. Check your GitOps dependency chain
kubectl get kustomizations -A | grep -E "(cilium|networking|gateway)"
# Look for failed/blocked kustomizations

# 3. Find the root failure
kubectl get helmreleases -A
kubectl describe kustomization <failed-name> -n <namespace>
```

### Solution Pattern
When HelmReleases get stuck in failed states, Flux can't upgrade them - only install/uninstall works.

```bash
# Delete the failed HelmRelease to trigger clean recreation
kubectl delete helmrelease <cni-name> -n <namespace>

# Optionally force reconciliation to speed up recovery
flux reconcile kustomization <cni-name> -n <namespace>
```

### Verification Strategy
After fixing the root cause, verify the entire chain works:

```bash
# Resources should exist
kubectl get gateway -A
kubectl get services -A | grep LoadBalancer

# BGP should advertise all IPs (check your router's BGP table)
# DNS should automatically update (check external-dns logs)
```

### Key Learning for Homelab Adapters
- **Don't assume networking configuration issues first** - check if Kubernetes resources exist
- **Understand your dependency chains** - fix upstream before downstream
- **Failed HelmReleases need deletion, not patching** - Flux can't upgrade from failed states
- **BGP/DNS issues are often symptoms** - the real problem is usually missing Kubernetes resources

### Prevention Tips
- Monitor HelmRelease health: `kubectl get helmrelease -A`
- Use Flux reconciliation when kustomizations seem stuck
- Check resource existence before troubleshooting network configuration
- Remember: if Gateway API resources don't exist, your ingress won't work regardless of BGP/DNS configuration

---

## Commands for Homelab Users

### Basic Cluster Health Check
```bash
# Check individual node status
talosctl --nodes <node-ip> service kubelet
talosctl --nodes <node-ip> get members

# Check cluster-wide status
talosctl get members
talosctl service etcd
```

### Fix Talosconfig with Healthy Nodes
```bash
# Auto-detect and configure only healthy nodes
task talos:generate-config-healthy

# Manual specification of working nodes
task talos:generate-config-healthy NODES="10.0.5.215,10.0.5.220,10.0.5.100"
```