# Claude Project Memory

## OnePassword Connect Issue (Current)

**Problem**: OnePassword Connect credentials are corrupted, causing external-DNS to fail
- **GitHub Issue**: https://github.com/1Password/connect/issues/62
- **Symptoms**: 
  - Sync container error: `"illegal base64 data at input byte 0"`
  - ClusterSecretStore validation failed (status 500)
  - External-DNS blocked waiting for `onepassword-stores` dependency
- **Root Cause**: Credentials in `onepassword-secret` are improperly base64 encoded
- **Solution**: Need to double base64 encode the credentials file when creating the secret
- **Impact**: External-DNS can't update Ubiquiti router DNS or Cloudflare records