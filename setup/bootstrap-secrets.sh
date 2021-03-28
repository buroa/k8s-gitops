#!/bin/bash
export REPO_ROOT=$(git rev-parse --show-toplevel)

die() { echo "$*" 1>&2 ; exit 1; }

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "envsubst"
need "awk"

. "$REPO_ROOT"/setup/.env

# Path to Public Cert
PUB_CERT="$REPO_ROOT/setup/pub-cert.pem"
SECRETS_CACHE="$REPO_ROOT/.secrets_cache"
CLUSTER_PATH="$REPO_ROOT/cluster"

kseal() {
  name="$(basename -s .txt "$@")"
  namespace=$(echo "$@" | awk -F "/" '{print $1}')
  pubkey_checksum=$(cat $PUB_CERT | sha256sum | cut -d' ' -f1)
  path=$(dirname "$@")
  if output=$(envsubst < "$CLUSTER_PATH/$*"); then
    checksum="$(printf '%s %s' "$output" "$pubkey_checksum" | sha256sum)"

    if grep -q "$path/$name $checksum" $SECRETS_CACHE; then
      echo "Skipping $name"
    else
      echo "Writing $name to secret on $namespace namespace"

      # write to cache
      write_cache "$path/$name" "$checksum"

      if [[ "$name" == *"values" ]]; then
        input_arg="--from-file=values.yaml=/dev/stdin"
      else
        input_arg="--from-env-file=/dev/stdin"
      fi

      printf '%s' "$output" \
        | kubectl -n $namespace create secret generic $name --dry-run=client $input_arg -o yaml \
        | kubeseal --cert $PUB_CERT --format yaml \
        > "$CLUSTER_PATH/$path/$name-secret.yaml"
    fi
  fi
}

write_cache() {
  key=$1
  checksum=$2

  touch $SECRETS_CACHE
  echo "$key $checksum" >> $SECRETS_CACHE
  tmp_cache="$(tac $SECRETS_CACHE | awk '!seen[$1]++' | tac)"
  echo "$tmp_cache" > $SECRETS_CACHE
}

#kubeseal --fetch-cert --controller-name sealed-secrets --controller-namespace kube-system > setup/pub-cert.pem

for value in $(find $CLUSTER_PATH -name *.txt); do
  kseal $(realpath --relative-to=$CLUSTER_PATH $value)
done

