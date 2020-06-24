#!/bin/bash

# trap "exit" INT TERM
# trap "kill 0" EXIT

#set -x
export REPO_ROOT=$(git rev-parse --show-toplevel)

die() { echo "$*" 1>&2 ; exit 1; }

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "envsubst"

. "$REPO_ROOT"/setup/.env

# Path to Public Cert
PUB_CERT="$REPO_ROOT/setup/pub-cert.pem"

kseal() {
  name="$(basename -s .txt "$@")"
  namespace=$(echo "$@" | awk -F "/" '{print $1}')
  path=$(dirname "$@")
  echo "Writing $name to secret on $namespace namespace"
  if output=$(envsubst < "$REPO_ROOT/$*"); then
    printf '%s' "$output" \
      | kubectl -n $namespace create secret generic $name --dry-run=client --from-file=values.yaml=/dev/stdin -o yaml \
      | kubeseal --cert $PUB_CERT --format yaml \
      > "$REPO_ROOT/$path/$name-secret.yaml"
  fi
}

for value in $(find $REPO_ROOT -name *values.txt); do
  kseal $(realpath --relative-to=$REPO_ROOT $value)
done

