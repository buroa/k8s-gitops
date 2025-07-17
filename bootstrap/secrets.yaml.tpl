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
stringData:
  1password-credentials.json: op://homelab/1password/OP_CREDENTIALS_JSON
  token: op://homelab/1password/OP_CONNECT_TOKEN
