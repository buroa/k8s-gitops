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
    # WORKAROUND: Use data instead of stringData to prevent double base64 encoding
    # 1Password CLI returns credentials pre-base64 encoded, but stringData re-encodes them
    # When 1Password fixes this behavior, revert to stringData for both fields
    operator.1password.io/item-path: "vaults/homelab/items/1password"
    operator.1password.io/item-name: "1password"
data:
  1password-credentials.json: op://homelab/1password/OP_CREDENTIALS_JSON
stringData:
  token: op://homelab/1password/OP_CONNECT_TOKEN
