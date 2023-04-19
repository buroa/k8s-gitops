<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My personal kubernetes cluster ☸

_... managed with Flux, Renovate and GitHub Actions_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)
[![Kubernetes](https://img.shields.io/badge/v1.27.1-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k8s.io/)
[![Renovate](https://img.shields.io/github/actions/workflow/status/buroa/k8s-gitops/renovate.yaml?branch=master&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/buroa/k8s-gitops/actions/workflows/renovate.yaml)

[![Home-Internet](https://img.shields.io/uptimerobot/status/m794001384-01d2febd339773320ef5aae1?color=brightgreeen&label=Home%20Internet&style=for-the-badge&logo=v&logoColor=white)](https://uptimerobot.com)
[![Plex](https://img.shields.io/uptimerobot/status/m793802743-0b6044ca7f1ec92851b9a495?color=brightgreeen&label=Plex&style=for-the-badge&logo=v&logoColor=white)](https://plex.tv)
[![Overseerr](https://img.shields.io/uptimerobot/status/m793802757-ca314435a1d7b7dc1ca5dac9?color=brightgreeen&label=Overseerr&style=for-the-badge&logo=v&logoColor=white)](https://overseerr.dev)

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
- [cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [cilium](https://cilium.io): Internal Kubernetes networking plugin.
- [contour](https://projectcontour.io): Ingress controller.
- [external-secrets](https://github.com/external-secrets/external-secrets/): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Managed secrets for Kubernetes.
- [volsync](https://github.com/backube/volsync): Backup and recovery of persistent volume claims.

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

## ⭐ Stargazers

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=buroa/k8s-gitops&type=Date)](https://star-history.com/#buroa/k8s-gitops&Date)

</div>

---

## 🤝 Gratitude and Thanks

- [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops)
- [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops)
- [onedr0p/home-ops](https://github.com/onedr0p/home-ops)

---

## 📜 Changelog

See my _shitty_ [commit history](https://github.com/buroa/k8s-ops/commits/master)

---

## 🔏 License

See [LICENSE](./LICENSE)
