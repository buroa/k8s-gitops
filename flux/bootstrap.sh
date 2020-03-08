#!/bin/bash

kubectl apply -f namespace.yaml

for release in flux helm-operator; do
    echo "Installing $release"

    kubectl apply -f ${release}/${release}-release-values.yaml
    values_file=$(mktemp)
    kubectl get configmap ${release}-release-values -o json | jq -r '.data."values.yaml"' > $values_file
    helm upgrade --install $release --namespace flux --values  $values_file fluxcd/$release
done