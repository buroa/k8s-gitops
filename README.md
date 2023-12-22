<div align="center">

<img src="https://github.com/buroa/k8s-gitops/assets/36205263/14771e67-0c36-4b7c-923f-31f54529067d" align="center" width="144px" height="144px"/>

### My _geeked_ homelab k8s cluster ☸

_... automated via [Flux](https://fluxcd.io), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fburoa%2Fk8s-gitops%2Fmaster%2Fkubernetes%2Fapps%2Fkube-system%2Fsystem-upgrade-controller%2Fplans%2Fkubernetes.yaml&query=%24.spec.version&style=for-the-badge&logo=kubernetes&logoColor=white&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/buroa/k8s-gitops/renovate.yaml?branch=master&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/buroa/k8s-gitops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/uptimerobot/status/m794001384-01d2febd339773320ef5aae1?label=Home%20Internet&style=for-the-badge&logo=ubiquiti&logoColor=white)](https://status.ktwo.io)&nbsp;&nbsp;
[![Status-Page](https://img.shields.io/uptimerobot/status/m795945547-96a65141bdcd1c7325e874e9?label=Status%20Page&style=for-the-badge&logo=statuspage&logoColor=white)](https://status.ktwo.io)&nbsp;&nbsp;
[![Plex](https://img.shields.io/uptimerobot/status/m793802743-0b6044ca7f1ec92851b9a495?label=Plex&style=for-the-badge&logo=plex&logoColor=white)](https://status.ktwo.io/endpoints/_plex)&nbsp;&nbsp;

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.ktwo.io%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo)

</div>

---

## 📖 Overview

This is a repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Terraform](https://www.terraform.io), [Kubernetes](https://kubernetes.io), [Flux](https://fluxcd.io), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

There is a template over at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Installation

This semi hyper-converged cluster runs [Talos Linux](https://talos.dev), an immutable and ephemeral Linux distribution built for [Kubernetes](https://kubernetes.io), deployed on bare-metal [Apple Mac Minis](https://apple.com/mac-mini). [Rook](https://rook.io) then provides my workloads with persistent block, object, and file storage; while a seperate server provides file storage for my media.

🔸 _[Click here](./talos/talconfig.yaml) to see my Talos configuration._

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [cilium](https://cilium.io): Internal Kubernetes networking plugin.
- [cert-manager](https://cert-manager.io): Creates SSL certificates for services in my Kubernetes cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [external-secrets](https://external-secrets.io): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.
- [rook](https://rook.io): Distributed block storage for peristent storage.
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes and Terraform which are commited to Git.
- [spegel](https://github.com/XenitAB/spegel): Stateless cluster local OCI registry mirror.
- [tf-controller](https://github.com/weaveworks/tf-controller): Additional Flux component used to run Terraform from within a Kubernetes cluster.
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

Below is a a high level look at the layout of how my directory structure with Flux works. In this brief example you are able to see that `authelia` will not be able to run until `lldap` and `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```mermaid
graph TD;
  id1>Kustomization: cluster] --> |Creates| id2>Kustomization: cluster-apps];
  id2>Kustomization: cluster-apps] --> |Creates| id3>Kustomization: cluster-apps-cloudnative-pg];
  id2>Kustomization: cluster-apps] --> |Creates| id6>Kustomization: cluster-apps-lldap]
  id2>Kustomization: cluster-apps] --> |Creates| id8>Kustomization: cluster-apps-authelia]
  id2>Kustomization: cluster-apps] --> |Creates| id5>Kustomization: cluster-apps-cloudnative-pg-cluster]
  id3 --> |Creates| id4(HelmRelease: postgres);
  id5 --> |Depends on| id3;
  id5 --> |Creates| id10(Cluster: Postgres);
  id6 --> |Creates| id7(HelmRelease: lldap);
  id6 --> |Depends on| id5;
  id8 --> |Creates| id9(HelmRelease: authelia);
  id8 --> |Depends on| id5;
  id8 --> |Depends on| id6;
```

### Networking

| Name                            | CIDR            |
|---------------------------------|-----------------|
| Kubernetes nodes                | `10.0.0.0/24`   |
| Kubernetes pods                 | `10.244.0.0/16` |
| Kubernetes services             | `10.245.0.0/16` |
| Kubernetes external services    | `10.0.3.0/24`   |
| Thunderbolt network (rook-ceph) | `10.1.0.0/24`   |

- [cilium](https://github.com/cilium/cilium) is configured with the `io.cilium/lb-ipam-ips` annotation to expose Kubernetes services with their own IP over L3 (BGP), which is configured on my router. L2 (ARP) can also be announced in addition to L3 via the `io.cilium/lb-ipam-layer2` label.
- [cloudflared](https://github.com/cloudflare/cloudflared) provides a [secure tunnel](https://www.cloudflare.com/products/tunnel) for [Cloudflare](https://www.cloudflare.com) to ingress into [ingress-nginx](https://github.com/kubernetes/ingress-nginx), my ingress controller.

🔸 _[Click here](./kubernetes/apps/networking/cloudflared/app/configs/config.yaml) to see my `cloudflared` configuration._

---

## 🌐 DNS

<details>
  <summary>Click to see my high level network diagram</summary>

```mermaid
graph TD;
  id1>Client] --> id2>UDM Pro];
  id2 --> id3>blocky];
  id2 --> |fallback| id4>1.1.1.1];
  id3 --> |ktwo.io| id5>k8s-gateway];
  id3 --> |cluster.local| id6>coredns];
  id3 --> |else| id7>blocklists];
  id7 --> id4;
  id5 --> id8>/etc/hosts];
  id5 --> id9>Ingress];
  id5 --> |else| id4;
```
</details>

### Internal DNS

The UDM Pro resolves DNS queries via [blocky](https://github.com/0xERR0R/blocky), which provides first-hop DNS resolution for my network. `Blocky` forwards requests targeted towards my public domain via [k8s-gateway](https://github.com/ori-edge/k8s_gateway). Last-hop DNS resolution resolves via [1.1.1.1](https://1.1.1.1/dns/), which is configured as my primary DNS upstream provider. If for any reason `blocky` becomes unavailable, the UDM Pro is configured to fallback to `1.1.1.1` until blocky becomes available again.

🔸 _[Click here](./kubernetes/apps/networking/blocky/app/configs/config.yml) to see my `blocky` configuration or [here](./kubernetes/apps/networking/k8s-gateway/app/configs/Corefile) to see my `k8s-gateway` configuration._

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configured to sync DNS records to [Cloudflare](https://www.cloudflare.com/) using ingresses `external-dns.alpha.kubernetes.io/target` annotation.

---

## 🔧 Hardware

<details>
  <summary>Click to see my rack</summary>

  <img src="https://github.com/buroa/k8s-gitops/assets/36205263/516d9f08-9bbd-443f-a01f-62089fdc6acc" align="center" alt="rack"/>
</details>

| Device                                   | Count | OS Disk Size | Data Disk Size      | Ram  | Operating System | Purpose             |
|------------------------------------------|-------|--------------|---------------------|------|------------------|---------------------|
| Apple Mac Mini (3.2GHz Intel i7 + 10GbE) | 3     | 1TB NVMe     | -                   | 64GB | Talos            | Kubernetes Workers  |
| Apple Mac Mini (3.2GHz Intel i7)         | 3     | 512GB NVMe   | -                   | 32GB | Talos            | Kubernetes Masters  |
| CyberPower ATS PDU                       | 1     | -            | -                   | -    | -                | PDU                 |
| CyberPower UPS                           | 1     | -            | -                   | -    | -                | PSU                 |
| Sabrent NVMe M.2 Thunderbolt 3 Enclosure | 6     | -            | 2TB NVMe ea.        | -    | -                | Rook Ceph / Workers |
| Sonnet 10GbE Thunderbolt 3 Adapter       | 3     | -            | -                   | -    | -                | 10GbE / Masters     |
| Synology NAS RS1221+                     | 1     | -            | 8x22TB + 2x2TB NVMe | 32GB | -                | NFS                 |
| Ubiquiti UDM Pro                         | 1     | -            | -                   | -    | -                | Router              |
| Ubiquiti USW Enterprise XG 24            | 1     | -            | -                   | -    | -                | 10GbE Switch        |

---

## ⭐ Stargazers

<div align="center">

<a href="https://star-history.com/#buroa/k8s-gitops&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=buroa/k8s-gitops&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=buroa/k8s-gitops&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=buroa/k8s-gitops&type=Date" />
  </picture>
</a>

</div>

---

## 🤝 Gratitude and Thanks

 Many thanks to my friend [@onedrop](https://github.com/onedr0p) and all the fantastic people who donate their time to the [Home Operations](https://discord.gg/home-operations) Discord community. Be sure to check out [kubesearch.dev](https://kubesearch.dev) for ideas on how to deploy applications or get ideas on what you may deploy.

---

## 📜 Changelog

See the latest [release](https://github.com/buroa/k8s-gitops/releases/latest) notes.

---

## 🔏 License

See [LICENSE](./LICENSE).
