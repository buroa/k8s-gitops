---
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-secret
  namespace: external-secrets
stringData:
  1password-credentials.json: op://$VAULT/1password/OP_CREDENTIALS_JSON
  token: op://$VAULT/1password/OP_CONNECT_TOKEN
