# Bootstrap

## Talos

### Create Talos Secrets

```
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
task talos:genconfig
```

### Apply Talos Config

```
task talos:apply-config node=m0.k8s.ktwo.io
task talos:apply-config node=m1.k8s.ktwo.io
task talos:apply-config node=m2.k8s.ktwo.io
task talos:apply-config node=w0.k8s.ktwo.io
task talos:apply-config node=w1.k8s.ktwo.io
task talos:apply-config node=w2.k8s.ktwo.io
```

### Update Mac EFI

_use reFINd ensure boot order and delete other boot entries_

1. Download [refind](https://sourceforge.net/projects/refind/files/0.14.0/refind-flashdrive-0.14.0.zip/download) here
2. Add [exfat_x64.efi](https://github.com/pbatard/efifs/releases/download/v1.9/exfat_x64.efi) driver
3. Set boot order to Talos: `bcfg boot add 0 fs1:\EFI\BOOT\BOOTX64.efi "Talos"`

If you don't do this, your system reboots will be _extremely_ slow.

### Boostrap Talos

```
talosctl -n m0.k8s.ktwo.io bootstrap
talosctl -n m0.k8s.ktwo.io kubeconfig -f
kubectl get no -o wide
```

### Bootstrap CNI

```
kubectl kustomize --enable-helm ./cni | kubectl apply -f -
kubectl kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -
```
