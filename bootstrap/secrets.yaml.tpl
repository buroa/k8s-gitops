---
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
# onepassword-secret is managed manually due to encoding issues
# DO NOT add back to this template - it causes Groundhog Day encoding loops
# Manual fix: kubectl create secret generic onepassword-secret --namespace external-secrets --from-literal="1password-credentials.json=$CREDS_DECODED" --from-literal="token=$TOKEN"
