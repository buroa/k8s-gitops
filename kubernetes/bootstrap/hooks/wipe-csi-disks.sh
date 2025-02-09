#!/usr/bin/env bash

wipe_csi_disks() {
    local nodes=$(talosctl config info --output json | jq --raw-output '.nodes | .[]')

    for node in $nodes; do
        disks=$(
            talosctl --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.CSI_DISK) | .metadata.id' \
                | xargs
        )
        talosctl --nodes "${node}" wipe disk $disks
    done
}

main() {
    wipe_csi_disks
}

main
