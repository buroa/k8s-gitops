<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My _geeked_ homelab k8s cluster ☸

_... automated via [Flux](https://fluxcd.io), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)
[![Kubernetes](https://img.shields.io/badge/v1.27.4-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k8s.io/)
[![Renovate](https://img.shields.io/github/actions/workflow/status/buroa/k8s-gitops/renovate.yaml?branch=master&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/buroa/k8s-gitops/actions/workflows/renovate.yaml)

[![Home-Internet](https://img.shields.io/uptimerobot/status/m794001384-01d2febd339773320ef5aae1?label=Home%20Internet&style=for-the-badge&logo=kubernetes&logoColor=white)](https://ln.ktwo.io/status)
[![Plex](https://img.shields.io/uptimerobot/status/m793802743-0b6044ca7f1ec92851b9a495?label=Plex&style=for-the-badge&logo=plex&logoColor=white)](https://ln.ktwo.io/status)
[![Overseerr](https://img.shields.io/uptimerobot/status/m793802757-ca314435a1d7b7dc1ca5dac9?label=Overseerr&style=for-the-badge&logo=insomnia&logoColor=white)](https://ln.ktwo.io/status)

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. It is deployed and managed using tools like [Talos](https://talos.dev/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

### Installation

This semi hyper-converged cluster runs [Talos Linux](https://talos.dev), an immutable and ephemeral Linux distribution built for [Kubernetes](https://k8s.io), deployed on bare-metal [Apple Mac Mini's](https://apple.com/mac-mini). [Rook](https://rook.io) then provides my workloads with persistent block, object, and file storage; while a seperate server provides file storage for my media.

🔸 _[Click here](./talos/talconfig.yaml) to see my Talos configuration._

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [cilium](https://cilium.io): Internal Kubernetes networking plugin.
- [cert-manager](https://cert-manager.io): Creates SSL certificates for services in my Kubernetes cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [external-secrets](https://external-secrets.io): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.
- [rook](https://rook.io): Distributed block storage for peristent storage.
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes, Ansible and Terraform which are commited to Git.
- [volsync](https://github.com/backube/volsync) and [snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations. Those Flux kustomizations will generally have a `HelmRelease` or other resources related to the application underneath it which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes/).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation
├─📁 flux          # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
```

### Cluster layout

Below is a a high level look at the layout of how my directory structure with Flux works. In this brief example you are able to see that `authelia` will not be able to run until `lldap` and `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```python
# Key: <kind> :: <metadata.name>
GitRepository :: k8s-gitops
    Kustomization :: cluster
        Kustomization :: cluster-apps
            Kustomization :: cluster-apps-authelia
                DependsOn:
                    Kustomization :: cluster-apps-lldap
                    Kustomization :: cluster-apps-cloudnative-pg-cluster
                HelmRelease :: authelia
            Kustomization :: cluster-apps-lldap
                HelmRelease :: lldap
            Kustomization :: cluster-apps-cloudnative-pg
                HelmRelease :: cloudnative-pg
            Kustomization :: cluster-apps-cloudnative-pg-cluster
                DependsOn:
                    Kustomization :: cluster-apps-cloudnative-pg
                Cluster :: postgres
```

### Networking

| Name                         | CIDR            |
| ---------------------------- | --------------- |
| Kubernetes nodes             | `10.0.0.0/24`   |
| Kubernetes pods              | `10.244.0.0/16` |
| Kubernetes services          | `10.245.0.0/16` |
| Kubernetes external services | `10.0.3.0/24`   |

- [cilium](https://github.com/cilium/cilium) is configured with the `io.cilium/lb-ipam-ips` annotation to expose Kubernetes services with their own IP over L3 (BGP), which is configured on my router. L2 (ARP) can also be announced in addition to L3 via the `io.cilium/lb-ipam-layer2` label.
- [cloudflared](https://github.com/cloudflare/cloudflared) provides a [secure tunnel](https://www.cloudflare.com/products/tunnel) for [Cloudflare](https://www.cloudflare.com) to ingress into [ingress-nginx](https://github.com/kubernetes/ingress-nginx), my ingress controller.

🔸 _[Click here](./kubernetes/apps/networking/cloudflared/app/configs/config.yaml) to see my `cloudflared` configuration._

---

## 🌐 DNS

### Internal DNS

The UDM Pro resolves DNS queries via [blocky](https://github.com/0xERR0R/blocky), which provides first-hop DNS resolution for my network. `Blocky` forwards requests targeted towards my public domain via [k8s-gateway](https://github.com/ori-edge/k8s_gateway). Last-hop DNS resolution resolves via [1.1.1.1](https://1.1.1.1/dns/), which is configured as my primary DNS upstream provider. If for any reason `blocky` becomes unavailable, the UDM Pro is configured to fallback to `1.1.1.1` until blocky becomes available again.

🔸 _[Click here](./kubernetes/apps/networking/blocky/app/configs/config.yml) to see my `blocky` configuration or [here](./kubernetes/apps/networking/k8s-gateway/app/configs/Corefile) to see my `k8s-gateway` configuration._

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configured to sync DNS records to [Cloudflare](https://www.cloudflare.com/) using ingresses `external-dns.alpha.kubernetes.io/target` annotation.

---

## 🔧 Hardware

| Device                      | Count | OS Disk Size | Data Disk Size           | Ram  | Operating System | Purpose            |
| --------------------------- | ----- | ------------ | ------------------------ | ---- | ---------------- | ------------------ |
| Unifi UDM Pro               | 1     | -            | -                        | -    | -                | Router             |
| Unifi USW Enterprise XG 24  | 1     | -            | -                        | -    | -                | Switch             |
| Apple Mac Mini (18' 3.2GHz) | 3     | 512GB NVMe   | -                        | 32GB | Talos            | Kubernetes Masters |
| Apple Mac Mini (18' 3.2Ghz) | 3     | 1TB NVMe     | 2x 2TB NVMe (rook-ceph)  | 64GB | Talos            | Kubernetes Workers |
| Synology NAS RS820+         | 1     | -            | 4x16TB w/ 2TB NVMe cache | 16GB | -                | NFS                |
| CyberPower ATS PDU          | 1     | -            | -                        | -    | -                | PDU                |
| CyberPower UPS              | 1     | -            | -                        | -    | -                | PSU                |

---

## ⭐ Stargazers

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=buroa/k8s-gitops&type=Date)](https://star-history.com/#buroa/k8s-gitops&Date)

</div>

---

## 🤝 Gratitude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search) for ideas on how to deploy applications or get ideas on what you can deploy.

---

## 📜 Changelog

See my _shitty_ [commit history](https://github.com/buroa/k8s-gitops/commits/master)

---

## 🔏 License

See [LICENSE](./LICENSE)
