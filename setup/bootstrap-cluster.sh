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
      helm upgrade --install $release --namespace flux --values $values_file --set prometheus.enabled=false --set prometheus.serviceMonitor.create=false fluxcd/$release
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

installFlux

message "all done!"
kubectl get nodes -o=wide
