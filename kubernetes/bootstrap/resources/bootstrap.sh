#!/usr/bin/env bash

set -euo pipefail

function log() {
    echo -e "\033[0;32m[$(date --iso-8601=seconds)] (${FUNCNAME[1]}) $*\033[0m"
}

function wait_for_nodes() {
    if kubectl wait nodes --for=condition=Ready --all --timeout=10s &>/dev/null; then
        log "All nodes are ready. Skipping..."
        return
    fi
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10m &>/dev/null; do
        log "Waiting for all nodes to be up..."
        sleep 5
    done
}

function apply_prometheus_crds() {
    local -r crds=(
        "alertmanagerconfigs" "alertmanagers" "podmonitors" "probes"
        "prometheusagents" "prometheuses" "prometheusrules"
        "scrapeconfigs" "servicemonitors" "thanosrulers"
    )

    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0

    for crd in "${crds[@]}"; do
        if kubectl get crd "${crd}.monitoring.coreos.com" &>/dev/null; then
            log "Prometheus CRD '${crd}' is up-to-date. Skipping..."
            continue
        fi
        log "Applying Prometheus CRD '${crd}'..."
        kubectl apply --server-side \
            --filename "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${version}/example/prometheus-operator-crd/monitoring.coreos.com_${crd}.yaml"
    done
}

function apply_secrets() {
    local -r secrets_file="./resources/secrets.yaml.tpl"

    if op inject --in-file "${secrets_file}" | kubectl diff --filename - &>/dev/null; then
        log "Secret resources are up-to-date. Skipping..."
        return
    fi

    log "Applying secret resources..."
    op inject --in-file "${secrets_file}" | kubectl apply --server-side --filename -
}

function wipe_rook_disks() {
    if [[ -z "${ROOK_DISK:-}" ]]; then
        log "Environment variable ROOK_DISK is not set. Skipping..."
        return
    fi

    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        log "Rook is deployed in the cluster. Skipping..."
        return
    fi

    for node in $(talosctl config info --output json | jq --raw-output '.nodes | .[]'); do
        disk=$(
            talosctl --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.ROOK_DISK) | .metadata.id' \
                | xargs
        )

        if [[ -n "${disk}" ]]; then
            log "Wiping disk '${disk}' on node '${node}'..."
            talosctl --nodes "${node}" wipe disk "${disk}"
        else
            log "No disks matching '${ROOK_DISK:-}' on node '${node}'. Skipping..."
        fi
    done
}

function main() {
    wait_for_nodes
    apply_prometheus_crds
    apply_secrets
    wipe_rook_disks
}

main "$@"
