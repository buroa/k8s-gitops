set default-script
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l talos

[confirm('Apply Talos config to ' + node + ' [y|N] ?')]
[doc('Apply Talos config to a node')]
apply-node node *args:
    just talos render-config {{ node }} | talosctl -n {{ node }} apply-config -f /dev/stdin {{ args }}

[confirm('Reboot node ' + node + ' [y|N] ?')]
[doc('Reboot a node')]
reboot-node node *args:
    talosctl -n {{ node }} reboot {{ args }}

[doc('Render Talos config for a node')]
render-config node:
    export CONTROLPLANE="$(just talos machine-controller {{ node }})"
    export SCHEMATIC="$(just talos schematic-id)"
    talosctl machineconfig patch <(just template "{{ source_directory() }}/machineconfig.yaml.j2") \
        -p @<(just template "{{ source_directory() }}/networking.yaml.j2") \
        -p @<(just template "{{ source_directory() }}/nodes/{{ node }}.yaml.j2")

[confirm('Reset node ' + node + ' [y|N] ?')]
[doc('Reset a node')]
reset-node node *args:
    talosctl -n {{ node }} reset --reboot=true --graceful=false {{ args }}

[confirm('Shutdown node ' + node + ' [y|N] ?')]
[doc('Shutdown a node')]
shutdown-node node *args:
    talosctl -n {{ node }} shutdown --force {{ args }}

[confirm('Upgrade Kubernetes to ' + version + ' [y|N] ?')]
[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -r -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

[confirm('Upgrade node ' + node + ' [y|N] ?')]
[doc('Upgrade Talos version on a node')]
upgrade-node node *args:
    talosctl -n {{ node }} upgrade -i "$(just talos machine-image)" -m powercycle --timeout=10m {{ args }}

[doc('Generate a Talos schematic')]
schematic-id:
    export CONFIG_EARLY="$(just talos config-early)"
    curl -sX POST --data-binary @<(just template "{{ source_directory() }}/schematic.yaml.j2") "https://factory.talos.dev/schematics" | jq -r '.id'

[private]
machine-controller node:
    just template "{{ source_directory() }}/nodes/{{ node }}.yaml.j2" | yq -r -e 'select(.machine) | (.machine.type == "controlplane") // ""'

[private]
machine-image:
    export SCHEMATIC="$(just talos schematic-id)"
    just template "{{ source_directory() }}/machineconfig.yaml.j2" | yq -r -e 'select(.machine) | .machine.install.image'

[private]
config-early:
    just template "{{ source_directory() }}/networking.yaml.j2" | zstd --compress --ultra -22 | base64 -w 0
