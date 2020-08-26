#!/bin/bash
# set -x
# nodes
K3S_MASTER="k3s-0"
K3S_WORKERS_AMD64="k3s-1 k3s-2"
K3S_WORKERS_RPI_ARM64="k3s-pi3-a"
K3S_VERSION="v1.18.3+k3s1"

REPO_ROOT=$(git rev-parse --show-toplevel)
export KUBECONFIG="$REPO_ROOT/setup/kubeconfig"

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "curl"
need "ssh"
need "kubectl"
need "helm"

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

k3sMasterNode() {
  message "installing k3s master to $K3S_MASTER"
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "curl -sLS https://get.k3s.io | INSTALL_K3S_EXEC='server --tls-san $K3S_MASTER --no-deploy servicelb --no-deploy traefik --no-deploy local-storage --flannel-backend=host-gw' INSTALL_K3S_VERSION='$K3S_VERSION' sh -"
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/server: https:\/\/127.0.0.1:6443/server: https:\/\/$K3S_MASTER:6443/'" > "$REPO_ROOT/setup/kubeconfig"
  NODE_TOKEN=$(ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /var/lib/rancher/k3s/server/node-token")
}

ks3amd64WorkerNodes() {
  NODE_TOKEN=$(ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /var/lib/rancher/k3s/server/node-token")
  for node in $K3S_WORKERS_AMD64; do
    message "joining amd64 $node to $K3S_MASTER"
    EXTRA_ARGS=""

    ssh -o "StrictHostKeyChecking=no" ubuntu@"$node" "curl -sfL https://get.k3s.io | K3S_URL=https://k3s-0:6443 K3S_TOKEN=$NODE_TOKEN INSTALL_K3S_VERSION='$K3S_VERSION' sh -s - $EXTRA_ARGS"
  done
}

ks3arm64WorkerNodes() {
  NODE_TOKEN=$(ssh -o "StrictHostKeyChecking=no" ubuntu@"$K3S_MASTER" "sudo cat /var/lib/rancher/k3s/server/node-token")
  for node in $K3S_WORKERS_RPI_ARM64; do
    message "joining pi4 $node to $K3S_MASTER"
    EXTRA_ARGS=""

    ssh -o "StrictHostKeyChecking=no" ubuntu@"$node" "curl -sfL https://get.k3s.io | K3S_URL=https://k3s-0:6443 K3S_TOKEN=$NODE_TOKEN INSTALL_K3S_VERSION='$K3S_VERSION' sh -s - --node-taint arm=true:NoExecute $EXTRA_ARGS"
  done
}

installFlux() {
  message "installing flux"
  # install flux
  kubectl apply -f "$REPO_ROOT"/flux/namespace.yaml

  helm repo add fluxcd https://charts.fluxcd.io

  for release in flux helm-operator; do
      echo "Installing $release"

      kubectl apply -f "$REPO_ROOT"/flux/${release}/${release}-release-values.yaml
      values_file=$(mktemp)
      sleep 1
      kubectl get configmap -n flux ${release}-release-values -o json | jq -r '.data."values.yaml"' > $values_file
      helm install -name $release --namespace flux --values $values_file --set prometheus.enabled=false --set prometheus.serviceMonitor.create=false fluxcd/$release
  done

  FLUX_READY=1
  while [ $FLUX_READY != 0 ]; do
    echo "waiting for flux pod to be fully ready..."
    kubectl -n flux wait --for condition=available deployment/flux
    FLUX_READY="$?"
    sleep 5
  done

  # grab output the key
  FLUX_KEY=$(kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2)

  message "adding the key to github automatically"
  "$REPO_ROOT"/setup/add-repo-key.sh "$FLUX_KEY"
}

k3sMasterNode
ks3amd64WorkerNodes
ks3arm64WorkerNodes
installFlux

message "all done!"
kubectl get nodes -o=wide
