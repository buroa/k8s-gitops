# Home-Ops TODO

## In Progress

### qBittorrent Tools Migration (feat/qbittorrent-tools-tqm-qbr)
- [x] Remove existing qbtools configuration
- [x] Create qbr (qBittorrent Reannounce) configuration
- [x] Create tqm (Torrent Queue Manager) configuration
- [x] Update tools kustomization.yaml to reference new tools
- [ ] **Configure secrets for qBittorrent password and Radarr API key in tqm config**

## Pending

### Cherry-pick Analysis: qbittorrent-cli Configuration (Issue #4)
- [ ] **NOT RECOMMENDED for cherry-pick** - requires manual migration due to structural conflicts
- [ ] Evaluate adding qbittorrent-cli config (.qbt.toml) to current qBittorrent setup
- [ ] Consider restructuring tqm from tools/ to standalone app if needed
- [ ] Review removal of qbr tool and assess impact

## Completed

### OnePassword Connect Base64 Encoding Issue (RESOLVED)
- [x] **Diagnosed root cause**: 1Password CLI returns pre-base64 encoded credentials, but bootstrap template using `stringData` caused triple base64 encoding
- [x] **Applied permanent fix**: Modified `bootstrap/secrets.yaml.tpl` to use `data:` for credentials instead of `stringData:`
- [x] **Updated documentation**: CLAUDE.md and docs/1PASSWORD-SETUP.md reflect permanent fix
- [x] **Verified cluster health**: All Flux kustomizations Ready, 24/36 ExternalSecrets syncing successfully
- [x] **Confirmed Cilium networking**: eBPF datapath working, LoadBalancer services functional, Gateway API enabled
- [x] **Network routing investigation**: kube-vip LoadBalancer IP (10.0.48.55) not accessible from client network due to VLAN 48 routing configuration (not a Kubernetes issue)

### Cluster Status Summary (2025-07-29)
- **Nodes**: 3 control-plane nodes healthy (Talos v1.10.5, Kubernetes v1.33.2)
- **Networking**: Cilium with eBPF, BGP control plane, L2 announcements for LoadBalancer IPs
- **Secrets**: OnePassword Connect working, ExternalSecrets syncing from 1Password vault "homelab"
- **Access**: Cluster accessible via DNS (homeops.hypyr.space:6443) and direct node IPs
- **Media Apps**: Intentionally disabled in .fluxignore, other applications healthy
