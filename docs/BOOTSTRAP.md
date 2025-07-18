# Talos Cluster Bootstrap Guide

## Prerequisites

- Talos nodes installed and accessible via network
- 1Password CLI (`op`) configured with homelab vault access
- Required tools installed via `mise`: `talosctl`, `kubectl`, `task`, `minijinja-cli`, `yq`

## Bootstrap Process

### 1. Generate Talos Secrets

Generate fresh secrets and store them in 1Password:

```bash
# Generate secrets and update 1Password automatically
task talos:gen-secrets
```

This task will:
- Generate new cluster secrets with `talosctl gen secrets`
- Extract all required values from secrets.yaml
- Store them in 1Password homelab vault under the talos item

### 2. Generate Talosconfig

Generate the client configuration with proper certificates:

```bash
# Generate talosconfig with matching certificates from 1Password
task talos:generate-config
```

This task will:
- Render the machine config template with 1Password secrets
- Extract the CA certificate and key
- Generate a properly formatted talosconfig file
- Configure endpoints and nodes automatically

### 3. Apply Configuration to Nodes

Apply configuration to both control plane nodes using tasks:

```bash
# Apply to first node
task talos:apply-node NODE=10.0.5.196

# Apply to second node  
task talos:apply-node NODE=10.0.5.78
```

The tasks automatically:
- Render the machine config template with environment variables
- Inject 1Password secrets 
- Apply the configuration with proper node-specific patches

### 4. Bootstrap Cluster

Bootstrap etcd on one node only:

```bash
# Bootstrap the cluster using task
task bootstrap:talos -y
```

**Note**: Only bootstrap one node. The other node will join automatically.

### 5. Verify Cluster

Check cluster status:

```bash
# Check cluster members
talosctl --nodes 10.0.5.78 get members

# Generate kubeconfig using task
task talos:kubeconfig

# Verify Kubernetes cluster
kubectl get nodes
kubectl get pods -A
```

### 6. Bootstrap Applications

Once the cluster is operational, bootstrap core applications:

```bash
task bootstrap:apps -y
```

## Troubleshooting

### Certificate Issues

If you encounter "not authorized" errors:

1. Regenerate secrets and talosconfig with matching certificates
2. Ensure the talosconfig uses proper client certificates (not CA as client cert)
3. Use `--insecure` flag for initial configuration application

### Node Communication

- Nodes should be able to communicate with each other
- VIP (homeops.hypyr.space) may not be available until CNI is installed
- Check node networking and firewall rules

### Console Access

- KVM console output is valuable for troubleshooting
- Consider setting up PXE boot for easier recovery/reinstallation

## Files Generated

- `secrets.yaml` - Talos cluster secrets
- `talos/talosconfig` - Client configuration
- `talos/controlplane.yaml` - Base machine configuration
- `kubernetes/kubeconfig` - Kubernetes client configuration

## Common Issues

1. **Mismatched certificates** - Regenerate talosconfig with matching secrets
2. **VIP not accessible** - Use direct node IP for initial bootstrap
3. **Multiple bootstrap attempts** - Only bootstrap one node, others join automatically
4. **CNI conflicts** - Ensure machine config `cni.name` is set to `none` to prevent Talos from installing default CNI
5. **Cilium device detection** - Ensure Cilium `devices` configuration matches actual network interfaces (`enp1s0` not `bond+`)
6. **Service subnet mismatch** - Verify cluster service subnet matches CoreDNS configuration (check `kubectl get svc kubernetes -o yaml`)
7. **Prometheus Operator CRDs** - Install CRDs before Cilium to avoid ServiceMonitor creation errors:
   ```bash
   kubectl apply --server-side -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.84.0/stripped-down-crds.yaml
   ```

## Configuration Issues Fixed

- **CNI Configuration**: Changed `cni.name` from `custom` to `none` in machine config template
- **Network Device**: Updated Cilium config to use `enp1s0` instead of `bond+`
- **Service Subnet**: Aligned CoreDNS service IP with actual cluster subnet (10.96.0.0/12)