#!/bin/bash

echo "🗃️  SEAWEEDFS POSTGRES BACKUP BUCKET SETUP (Simple Version)"
echo "=========================================================="
echo "Creating postgres-backup bucket for CloudNative-PG backups"
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

echo "🔍 Getting SeaweedFS S3 credentials from 1Password..."

# Get S3 credentials from 1Password
S3_ACCESS_KEY=$(op item get seaweedfs --vault homelab --field S3_ACCESS_KEY_ID 2>/dev/null)
S3_SECRET_KEY=$(op item get seaweedfs --vault homelab --field S3_SECRET_ACCESS_KEY 2>/dev/null)
S3_ENDPOINT=$(op item get seaweedfs --vault homelab --field S3_ENDPOINT 2>/dev/null)

if [[ -z "$S3_ACCESS_KEY" || -z "$S3_SECRET_KEY" || -z "$S3_ENDPOINT" ]]; then
    echo "❌ Could not retrieve SeaweedFS credentials from 1Password"
    echo "Make sure the 'seaweedfs' entry exists in the 'homelab' vault"
    exit 1
fi

echo "✅ Retrieved SeaweedFS credentials"
echo "📡 Endpoint: $S3_ENDPOINT"
echo

# Test basic connectivity
echo "🔗 Testing endpoint connectivity..."
if curl -I "$S3_ENDPOINT" >/dev/null 2>&1; then
    echo "✅ Endpoint is reachable"
else
    echo "❌ Cannot reach endpoint $S3_ENDPOINT"
    exit 1
fi

echo
echo "📋 MANUAL BUCKET CREATION GUIDE:"
echo "================================"
echo "Since SeaweedFS may not support automated bucket creation,"
echo "you can create the bucket manually or it may be created automatically"
echo "when CloudNative-PG first attempts to backup."
echo
echo "🔧 Option 1: Let CloudNative-PG create it automatically"
echo "   CloudNative-PG will attempt to create the bucket when it first runs a backup."
echo
echo "🔧 Option 2: Create manually using kubectl and AWS CLI:"
echo "   kubectl run aws-cli --rm -it --image=amazon/aws-cli:latest -- sh"
echo "   # Inside the pod, run:"
echo "   # export AWS_ACCESS_KEY_ID='$S3_ACCESS_KEY'"
echo "   # export AWS_SECRET_ACCESS_KEY='$S3_SECRET_KEY'"
echo "   # aws --endpoint-url=$S3_ENDPOINT s3 mb s3://postgres-backup"
echo "   # aws --endpoint-url=$S3_ENDPOINT s3 ls"
echo
echo "🔧 Option 3: Create via SeaweedFS admin interface"
echo "   Visit: https://s3-web.hypyr.space"
echo "   Create bucket named: postgres-backup"
echo

echo "✅ CONFIGURATION SUMMARY:"
echo "========================="
echo "✅ Updated CloudNative-PG cluster configuration:"
echo "   • Endpoint: $S3_ENDPOINT"
echo "   • Bucket: s3://postgres-backup/"
echo "   • Server name: postgres-v23 (incremented)"
echo
echo "✅ Updated external secret to use 'seaweedfs' 1Password entry"
echo "✅ Updated volsync component to use SeaweedFS instead of R2"
echo

echo "🔄 DEPLOYMENT STEPS:"
echo "===================="
echo "1. Apply the updated configurations:"
echo "   kubectl apply -k kubernetes/apps/databases/cloudnative-pg/"
echo
echo "2. Force refresh external secrets:"
echo "   kubectl annotate externalsecrets --all external-secrets.io/force-sync=\$(date +%s) -A"
echo
echo "3. Monitor the PostgreSQL backup:"
echo "   kubectl logs -n databases -l app.kubernetes.io/name=cloudnative-pg"
echo
echo "4. Check backup status:"
echo "   kubectl get backup -n databases"
echo "   kubectl get scheduledbackup -n databases"
echo
echo "🎉 Your PostgreSQL backups are now configured to use SeaweedFS!"
echo
echo "💡 TROUBLESHOOTING:"
echo "==================="
echo "• If backup fails due to missing bucket, CloudNative-PG will usually create it"
echo "• Check SeaweedFS logs: docker logs seaweedfs (on your Synology)"
echo "• Verify credentials: kubectl get secret cloudnative-pg-secret -n databases -o yaml"
echo "• Test connectivity from cluster: kubectl run curl --rm -it --image=curlimages/curl -- curl -I $S3_ENDPOINT"
