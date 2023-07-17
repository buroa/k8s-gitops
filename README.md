<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My _geeked_ homelab k8s cluster ☸

_... automated via [Flux](https://fluxcd.io/), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)
[![Kubernetes](https://img.shields.io/badge/v1.27.3-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k8s.io/)
[![Renovate](https://img.shields.io/github/actions/workflow/status/buroa/k8s-gitops/renovate.yaml?branch=master&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/buroa/k8s-gitops/actions/workflows/renovate.yaml)

[![Home-Internet](https://img.shields.io/uptimerobot/status/m794001384-01d2febd339773320ef5aae1?label=Home%20Internet&style=for-the-badge&logo=kubernetes&logoColor=white)](https://uptimerobot.com)
[![Plex](https://img.shields.io/uptimerobot/status/m793802743-0b6044ca7f1ec92851b9a495?label=Plex&style=for-the-badge&logo=plex&logoColor=white)](https://plex.tv)
[![Overseerr](https://img.shields.io/uptimerobot/status/m793802757-ca314435a1d7b7dc1ca5dac9?label=Overseerr&style=for-the-badge&logo=insomnia&logoColor=white)](https://overseerr.dev)

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. It is deployed and managed using tools like [Talos](https://talos.dev/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

### Installation

The cluster is running on [Talos Linux](https://talos.dev), an immutable and ephemeral Linux distribution built around [Kubernetes](https://k8s.io), deployed on bare-metal [Apple Mac Mini's](https://apple.com/mac-mini). [Rook Ceph](https://rook.io) is providing my workloads with persistent block, object, and file storage; while a seperate server provides file storage for my media.

🔸 _[Click here](./talos) to see my Talos configuration._

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [cilium](https://cilium.io): Internal Kubernetes networking plugin.
- [cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets/): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.
- [rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Managed secrets for Kubernetes, Ansible and Terraform which are commited to Git.
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

Below is a a high level look at the layout of how my directory structure with Flux works. In this brief example you are able to see that `authelia` will not be able to run until `glauth` and `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```python
# Key: <kind> :: <metadata.name>
GitRepository :: k8s-gitops
    Kustomization :: cluster
        Kustomization :: cluster-apps
            Kustomization :: cluster-apps-authelia
                DependsOn:
                    Kustomization :: cluster-apps-glauth
                    Kustomization :: cluster-apps-cloudnative-pg-cluster
                HelmRelease :: authelia
            Kustomization :: cluster-apps-glauth
                HelmRelease :: glauth
            Kustomization :: cluster-apps-cloudnative-pg
                HelmRelease :: cloudnative-pg
            Kustomization :: cluster-apps-cloudnative-pg-cluster
                DependsOn:
                    Kustomization :: cluster-apps-cloudnative-pg
                Cluster :: postgres
```

### Networking

| Name                                              | CIDR                           |
| ------------------------------------------------- | ------------------------------ |
| Kubernetes nodes                                  | `10.0.0.0/24`                  |
| Kubernetes pods                                   | `10.244.0.0/16`                |
| Kubernetes services                               | `10.245.0.0/16`                |
| Kubernetes external services (L2 or L3 w/ Cilium) | `10.0.0.192/26`, `10.0.3.0/24` |

- [Cilium](https://cilium.io) is configured with the `io.cilium/lb-ipam-ips` annotation and `io.cilium/lb-ipam-layer` label to expose Kubernetes services with their own IP over L2 or L3 (BGP) which is configured on my router.
- [cloudflared](https://github.com/cloudflare/cloudflared) provides a [secure tunnel](https://www.cloudflare.com/products/tunnel/) for [Cloudflare](https://www.cloudflare.com/) to ingress traffic from the Internet into my Kubernetes cluster.

---

## 🌐 DNS

### Internal DNS

[blocky](https://github.com/0xERR0R/blocky) provides the first hop of DNS resolution inside my network. DNS requests to my public domain are forwarded to [k8s-gateway](https://github.com/ori-edge/k8s_gateway) which checks to see if it's present in my cluster; if not, it talks out to [1.1.1.1](https://1.1.1.1) which is configured as my primary DNS provider.

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configured to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses this `external-dns` instance looks at to gather DNS records to put in `Cloudflare` are ones that have an annotation of `external-dns.alpha.kubernetes.io/target`.

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

Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search/) for ideas on how to deploy applications or get ideas on what you can deploy.

---

## 📜 Changelog

See my _shitty_ [commit history](https://github.com/buroa/k8s-gitops/commits/master)

---

## 🔏 License

See [LICENSE](./LICENSE)
