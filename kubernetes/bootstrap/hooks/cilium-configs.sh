#!/usr/bin/env bash

wait_for_crds() {
    local crds=(
        "ciliuml2announcementpolicies.cilium.io"
        "ciliumbgppeeringpolicies.cilium.io"
        "ciliumloadbalancerippools.cilium.io"
    )

    for crd in "${crds[@]}"; do
        until kubectl get crd "$crd" &>/dev/null; do
            echo "Waiting for ${crd} CRD to be available..."
            sleep 5
        done
    done
}

apply_configs() {
    echo "Applying Cilium configs..."
    kubectl apply \
        --namespace=kube-system \
        --server-side \
        --field-manager=kustomize-controller \
        --kustomize \
        "../apps/kube-system/cilium/configs"
}

main() {
    wait_for_crds
    apply_configs
}

main
