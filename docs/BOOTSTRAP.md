# Talos Cluster Bootstrap Guide

## Prerequi## Node Configuration

Your cluster consists of 3 control plane nodes:

- **home01** (10.0.5.219, EQ12) - Dual Ethernet bond (802.3ad LACP)
- **home02** (10.0.5.215, EQ12) - Dual Ethernet bond (802.3ad LACP)
- **home03** (10.0.5.100, NUC7) - Single Ethernet interface (eno1)

Static configurations are stored in `talos/static-configs/` by hostname.Talos nodes installed and accessible via network
- 1Password CLI (`op`) configured with homelab vault access
- Required tools installed via `mise`: `talosctl`, `kubectl`, `task`, `yq`

## Bootstrap Process

Simple 3-step process to bootstrap your Talos cluster:

### Step 1: Generate Talos Secrets

Generate fresh secrets and store them in 1Password:

```bash
# Generate secrets and update 1Password automatically
task talos:gen-secrets
```

### Step 2: Apply Node Configurations

Apply configurations to your nodes (auto-detects hostname and config):

```bash
# Apply to each node by IP (task auto-detects hostname and config file)
task talos:apply-config NODE=10.0.5.100   # home03 (NUC7)
task talos:apply-config NODE=10.0.5.215   # home02 (EQ12)
task talos:apply-config NODE=10.0.5.219   # home01 (EQ12)
```

### Step 3: Bootstrap Cluster

Bootstrap etcd on one node and generate kubeconfig:

```bash
# Bootstrap cluster on any control plane node
task talos:bootstrap NODE=10.0.5.100
task talos:kubeconfig
```

**Done!** Your cluster is running.

## Key Commands

```bash
task talos:gen-secrets                    # Generate and store cluster secrets
task talos:apply-config NODE=<IP>         # Apply config to node (auto-detects hostname)
task talos:bootstrap NODE=<IP>            # Bootstrap cluster
task talos:kubeconfig                     # Generate kubeconfig
```

## Verification

Check cluster status:

```bash
# Check cluster members
talosctl get members

# Verify Kubernetes cluster
kubectl get nodes
kubectl get pods -A
```

## Troubleshooting

### Certificate Issues

If you encounter "not authorized" errors:

1. Regenerate secrets and talosconfig: `task talos:gen-secrets`
2. Ensure 1Password CLI is authenticated: `op signin`
3. Verify node accessibility with `talosctl --nodes <IP> get hostname`

### Node Communication

- Nodes should be able to communicate with each other on the management network
- Check that nodes are reachable at their assigned IPs
- Verify network configuration and firewall rules
- Use `task talos:apply-config NODE=<IP>` to apply configurations

### Common Issues

- **Hostname detection fails**: Ensure the node is accessible and running Talos
- **Config file not found**: Check that `talos/static-configs/{hostname}.yaml` exists
- **1Password injection fails**: Verify `op` is signed in and has vault access

### Files Generated

- `secrets.yaml` - Talos cluster secrets
- `talos/talosconfig` - Client configuration
- `talos/static-configs/*.yaml` - Static node configurations
- `kubernetes/kubeconfig` - Kubernetes client configuration