---
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-secret
  namespace: external-secrets
  annotations:
    # FIXED: 1Password Connect requires double base64 encoding for credentials
    # This template provides single-encoded credentials that Kubernetes will encode again (double total)
    # Ref: https://github.com/1Password/connect-helm-charts/issues/202
    operator.1password.io/item-path: "vaults/homelab/items/1password"
    operator.1password.io/item-name: "1password"
stringData:
  # Pre-encode credentials once - K8s will encode again for required double encoding
  1password-credentials.json: $(op item get 1password --field OP_CREDENTIALS_JSON --vault homelab --reveal | base64 -d | sed 's/""/"/g' | base64 -w 0)
  # Token stays as-is (single encoding)
  token: $(op item get 1password --field OP_CONNECT_TOKEN --vault homelab --reveal)
