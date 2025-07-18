#!/bin/bash

echo "🌊 SEAWEEDFS → KUBERNETES INTEGRATION"
echo "===================================="
echo "Setting up SeaweedFS S3 credentials for volsync backups"
echo

# Check if 1Password CLI is available
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI not found. Please install it first."
    exit 1
fi

# Check if we're signed in to 1Password
if ! op account list &> /dev/null; then
    echo "❌ Not signed in to 1Password. Please run 'op signin' first."
    exit 1
fi

echo "🔍 Checking current S3 configuration..."

# Check for existing SeaweedFS entry
CURRENT_ENDPOINT=$(op item get seaweedfs --vault homelab --field S3_ENDPOINT 2>/dev/null || echo "")
CURRENT_ACCESS_KEY=$(op item get seaweedfs --vault homelab --field S3_ACCESS_KEY_ID 2>/dev/null || echo "")

echo "Current S3 configuration:"
echo "- Endpoint: ${CURRENT_ENDPOINT:-'Not set'}"
echo "- Access Key: ${CURRENT_ACCESS_KEY:-'Not set'}"
echo

if [[ "$CURRENT_ENDPOINT" == "https://s3.hypyr.space" ]]; then
    echo "✅ SeaweedFS is already configured as the S3 endpoint!"
    echo "🔄 Checking if credentials are properly set..."

    if [[ -n "$CURRENT_ACCESS_KEY" ]] && [[ "$CURRENT_ACCESS_KEY" == seaweedfs-* ]]; then
        echo "✅ SeaweedFS credentials are properly configured"
        echo
        echo "📋 Current Setup:"
        echo "================="
        echo "S3 Endpoint: $CURRENT_ENDPOINT"
        echo "Access Key: $CURRENT_ACCESS_KEY"
        echo "Bucket: volsync"
        echo
        echo "🎉 Your cluster is ready to use SeaweedFS for volsync backups!"
        echo
        echo "💡 NEXT STEPS:"
        echo "=============="
        echo "1. Ensure your cluster has the external-secrets operator running"
        echo "2. Apply any applications with volsync enabled"
        echo "3. Monitor backup status via: kubectl get replicationsources -A"
        echo "4. View SeaweedFS admin UI: https://s3-web.hypyr.space"
        exit 0
    fi
fi

echo "🔧 Setting up SeaweedFS integration..."

# Generate secure credentials if not already set
if [[ -z "$CURRENT_ACCESS_KEY" ]] || [[ "$CURRENT_ACCESS_KEY" != seaweedfs-* ]]; then
    echo "🔑 Generating new SeaweedFS credentials..."
    S3_ACCESS_KEY="seaweedfs-$(openssl rand -hex 8)"
    S3_SECRET_KEY=$(openssl rand -base64 32)

    echo "Generated credentials:"
    echo "- Access Key: $S3_ACCESS_KEY"
    echo "- Secret Key: $S3_SECRET_KEY"
    echo
else
    echo "🔄 Using existing SeaweedFS credentials..."
    S3_ACCESS_KEY="$CURRENT_ACCESS_KEY"
    S3_SECRET_KEY=$(op item get seaweedfs --vault homelab --field S3_SECRET_ACCESS_KEY --reveal)
fi

# Create or update dedicated SeaweedFS 1Password entry
echo "💾 Creating/updating SeaweedFS 1Password entry..."

# Check if seaweedfs entry exists
if op item get seaweedfs --vault homelab >/dev/null 2>&1; then
    echo "� Updating existing SeaweedFS entry..."
    op item edit seaweedfs --vault homelab \
        "S3_ACCESS_KEY_ID[text]=$S3_ACCESS_KEY" \
        "S3_SECRET_ACCESS_KEY[concealed]=$S3_SECRET_KEY" \
        "S3_ENDPOINT[text]=https://s3.hypyr.space" \
        "S3_REGION[text]=us-east-1" \
        "REPOSITORY_TEMPLATE[text]=s3:https://s3.hypyr.space/volsync" \
        "RESTIC_PASSWORD[concealed]=$(openssl rand -base64 32)"
else
    echo "🆕 Creating new SeaweedFS entry..."
    op item create \
        --category="Login" \
        --title="seaweedfs" \
        --vault="homelab" \
        --url="https://s3-web.hypyr.space" \
        "username[text]=seaweedfs" \
        "password[password]=$S3_SECRET_KEY" \
        "S3_ACCESS_KEY_ID[text]=$S3_ACCESS_KEY" \
        "S3_SECRET_ACCESS_KEY[concealed]=$S3_SECRET_KEY" \
        "S3_ENDPOINT[text]=https://s3.hypyr.space" \
        "S3_REGION[text]=us-east-1" \
        "REPOSITORY_TEMPLATE[text]=s3:https://s3.hypyr.space/volsync" \
        "RESTIC_PASSWORD[concealed]=$(openssl rand -base64 32)"
fi

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully updated 1Password with SeaweedFS credentials"
else
    echo "❌ Failed to update 1Password"
    exit 1
fi

# Clean up old S3 fields from cloudflare entry
echo "🧹 Cleaning up old S3 fields from cloudflare entry..."
if op item get cloudflare --vault homelab --field S3_ENDPOINT >/dev/null 2>&1; then
    echo "📝 Found S3 fields in cloudflare entry - these should be removed"
    echo "⚠️  Please manually remove these S3 fields from the cloudflare 1Password entry:"
    echo "   - S3_ACCESS_KEY_ID"
    echo "   - S3_SECRET_ACCESS_KEY"
    echo "   - S3_ENDPOINT"
    echo "   - S3_REGION"
    echo "ℹ️  The cluster now uses the dedicated 'seaweedfs' entry instead"
else
    echo "✅ Cloudflare entry doesn't have S3 fields (already clean)"
fi

echo
echo "🧪 Testing S3 connectivity..."

# Test S3 API connectivity
if curl -sI https://s3.hypyr.space >/dev/null 2>&1; then
    echo "✅ S3 API endpoint is accessible"
else
    echo "⚠️  S3 API endpoint test failed - check DNS/reverse proxy setup"
fi

# Test Web UI connectivity
if curl -sI https://s3-web.hypyr.space >/dev/null 2>&1; then
    echo "✅ Web UI endpoint is accessible"
else
    echo "⚠️  Web UI endpoint test failed - check DNS/reverse proxy setup"
fi

echo
echo "📋 SEAWEEDFS INTEGRATION COMPLETE"
echo "================================="
echo "S3 Endpoint: https://s3.hypyr.space"
echo "Access Key: $S3_ACCESS_KEY"
echo "Secret Key: [stored in 1Password]"
echo "Bucket: volsync"
echo "Region: us-east-1"
echo
echo "🌐 Admin UI: https://s3-web.hypyr.space"
echo "🔍 Monitor: kubectl get replicationsources -A"
echo
echo "🎉 Your Kubernetes cluster can now backup to SeaweedFS!"
echo
echo "💡 NEXT STEPS:"
echo "=============="
echo "1. Ensure external-secrets operator is running in your cluster"
echo "2. Apply applications with volsync backup enabled"
echo "3. Check backup jobs: kubectl get jobs -n <app-namespace>"
echo "4. Monitor storage usage via the SeaweedFS Web UI"
echo
echo "🔄 REFRESH EXTERNAL SECRETS:"
echo "============================"
echo "If your cluster is already running, refresh the external secrets:"
echo "kubectl annotate externalsecrets --all external-secrets.io/force-sync=\$(date +%s) -A"
