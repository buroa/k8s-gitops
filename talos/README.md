# Bootstrap

## Talos

### Create Talos Secrets

```
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
talhelper genconfig
export TALOSCONFIG=~/k8s-gitops/talos/clusterconfig/talosconfig
```

```
talosctl -n 10.0.0.10 apply-config --file clusterconfig/k8s-m0*.yaml --insecure
talosctl -n 10.0.0.11 apply-config --file clusterconfig/k8s-m1*.yaml --insecure
talosctl -n 10.0.0.12 apply-config --file clusterconfig/k8s-m2*.yaml --insecure
talosctl -n 10.0.0.20 apply-config --file clusterconfig/k8s-w0*.yaml --insecure
talosctl -n 10.0.0.21 apply-config --file clusterconfig/k8s-w1*.yaml --insecure
talosctl -n 10.0.0.22 apply-config --file clusterconfig/k8s-w2*.yaml --insecure
```

### Pre Mac Setup

_use reFINd ensure boot order and delete other boot entries_

1. Download [refind](https://sourceforge.net/projects/refind/files/0.14.0/refind-flashdrive-0.14.0.zip/download) here
2. Add [exfat_x64.efi](https://github.com/pbatard/efifs/releases/download/v1.9/exfat_x64.efi) driver
3. Set boot order to Talos: `bcfg boot add 0 fs1:\EFI\BOOT\BOOTX64.efi "Talos"`

If you don't do this, your system reboots will be _extremely_ slow.

### Post Mac Setup

```
talosctl -n 10.0.0.10 bootstrap
talosctl -n 10.0.0.10 kubeconfig -f
kubectl get no -o wide
```

### Post Talos Setup

```
kubectl kustomize --enable-helm ./cni | kubectl apply -f -
kubectl kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -
```
