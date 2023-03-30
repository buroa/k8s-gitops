# create talos cluster

talhelper gensecret > talsecret.sops.yaml  
sops -e -i talsecret.sops.yaml

talhelper genconfig

export TALOSCONFIG=~/k8s-gitops/talos/clusterconfig/talosconfig

talosctl -n 10.0.0.10 apply-config --file clusterconfig/k8s-m0*.yaml --insecure  
talosctl -n 10.0.0.11 apply-config --file clusterconfig/k8s-m1*.yaml --insecure  
talosctl -n 10.0.0.12 apply-config --file clusterconfig/k8s-m2*.yaml --insecure  
talosctl -n 10.0.0.20 apply-config --file clusterconfig/k8s-w0*.yaml --insecure  
talosctl -n 10.0.0.21 apply-config --file clusterconfig/k8s-w1*.yaml --insecure  
talosctl -n 10.0.0.22 apply-config --file clusterconfig/k8s-w2*.yaml --insecure

# pre macm boot setup

macs dont like the vfat efi partition talos creates  
we need to reboot the mac into disk mode (hold T)  
connect the thunderbolt cable from macm <> laptop and run the following

sudo gdisk (macm disk)

> d  
> 1 (efi partition)  
> n  
> 1 (efi partition)  
> 0700 (microsoft)  
> w

open disk utility and erase the partition and re-format

sudo gdisk (macm disk)

> t  
> 1  
> ef00 (efi code)  
> c  
> 1  
> EFI (change partition label)  
> w

mount the efi macm partition  
add back \EFI\boot\bootx64.efi from original talos efi partition  
reboot

using reFINd ensure macm boot order

> delete other boot entries  
> bcfg boot add 0 fs1:\EFI\boot\boot64.efi "Talos"  
> set default boot entry

reboot

# post macm boot setup

talosctl -n 10.0.0.10 bootstrap  
talosctl -n 10.0.0.10 kubeconfig -f  
kubectl get no -o wide

# post talos cluster

kubectl kustomize --enable-helm ./cni | kubectl apply -f -  
kubectl kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -
