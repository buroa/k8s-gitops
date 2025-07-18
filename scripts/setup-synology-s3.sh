#!/bin/bash

echo "🗄️  SYNOLOGY NAS → S3 SETUP (GARAGE)"
echo "====================================="
echo "Configuring Garage as lightweight S3 storage for volsync backups"
echo

echo "This script will:"
echo "1. Complete your cloudflare 1Password entry with S3 credentials"
echo "2. Update the repository template for your NAS endpoint"
echo "3. Replace Cloudflare R2 with your local Garage S3 storage"
echo

# Check current setup
echo "📋 Current Configuration:"
echo "========================"
echo "Repository Template: $(op item get volsync-s3-template --vault homelab --field REPOSITORY_TEMPLATE)"
echo "S3 Endpoint: s3.hypyr.space"
echo

echo "🔧 Setup Steps for Garage (Lightweight S3):"
echo "============================================="
echo "1. SSH to your NAS (barbary.hypyr.space)"
echo "2. Install Garage via Docker:"
echo "   docker run -d --name garage \\"
echo "     -p 3900:3900 -p 3901:3901 \\"
echo "     -v /path/to/garage/meta:/data \\"
echo "     -v /path/to/garage/data:/data \\"
echo "     dxflrs/garage:v1.0.1"
echo "3. Configure Garage with garage.toml"
echo "4. Create bucket and keys via garage CLI"
echo

echo "🔐 S3 Credentials Setup:"
echo "========================"
echo "You'll need:"
echo "- S3 Access Key ID (from Garage)"
echo "- S3 Secret Access Key (from Garage)"
echo "- S3 Endpoint URL (http://razzia.hypyr.space:3900 or https://s3.hypyr.space)"
echo

read -p "Have you set up Garage and have the credentials? (y/N): " READY
if [[ $READY != [yY] ]]; then
    echo
    echo "⚠️  Please set up Garage first:"
    echo "1. SSH to your NAS: ssh cpritchett@razzia.hypyr.space"
    echo "2. Create garage config directory: mkdir -p /volume1/docker/garage/{data,meta}"
    echo "3. Create garage.toml config file"
    echo "4. Run Garage container"
    echo "5. Create bucket and access keys"
    echo "6. Run this script again"
    echo
    echo "📁 Quick Garage setup commands:"
    echo "docker run -d --name garage \\"
    echo "  -p 3900:3900 -p 3901:3901 \\"
    echo "  -v /volume1/docker/garage/meta:/etc/garage.toml \\"
    echo "  -v /volume1/docker/garage/data:/data \\"
    echo "  dxflrs/garage:v1.0.1"
    exit 0
fi

echo
echo "📝 Enter your Garage S3 credentials:"
echo "==================================="
read -p "S3 Access Key ID: " S3_ACCESS_KEY
read -p "S3 Secret Access Key: " S3_SECRET_KEY
read -p "S3 Endpoint URL (e.g., https://s3.hypyr.space): " S3_ENDPOINT
read -p "Repository path (default: volsync): " REPO_PATH
REPO_PATH=${REPO_PATH:-volsync}

echo
echo "💾 Updating cloudflare 1Password entry with S3 credentials..."

# Get current cloudflare token
CF_TOKEN=$(op item get cloudflare --vault homelab --field CF_API_TOKEN --reveal)

# Delete current entry and recreate with all needed fields
op item delete cloudflare --vault homelab

# Create comprehensive cloudflare entry
op item create \
  --category="API Credential" \
  --title="cloudflare" \
  --vault="homelab" \
  "CF_API_TOKEN[concealed]=$CF_TOKEN" \
  "AWS_ACCESS_KEY_ID[concealed]=$S3_ACCESS_KEY" \
  "AWS_SECRET_ACCESS_KEY[concealed]=$S3_SECRET_KEY" \
  "CLOUDFLARE_API_TOKEN[concealed]=$CF_TOKEN" \
  "REPOSITORY_TEMPLATE[text]=$S3_ENDPOINT/$REPO_PATH"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully updated cloudflare entry with S3 credentials"
    echo
    echo "🔧 S3 Configuration Summary:"
    echo "==========================="
    echo "Endpoint: $S3_ENDPOINT"
    echo "Bucket: $REPO_PATH"
    echo "Access Key: $S3_ACCESS_KEY"
    echo "Repository Template: $S3_ENDPOINT/$REPO_PATH"
    echo
    echo "🎉 Your volsync backups will now use Garage on your Synology NAS!"
    echo
    echo "📝 Next Steps:"
    echo "============="
    echo "1. Test backup: kubectl create job --from=cronjob/<app>-backup <app>-backup-manual -n <namespace>"
    echo "2. Monitor logs: kubectl logs -f job/<app>-backup-manual -n <namespace>"
    echo "3. Verify in Garage that backups appear in 'volsync' bucket"
    echo
    echo "💡 Benefits of using Garage:"
    echo "- Lightweight and efficient"
    echo "- Faster local backups (no internet required)"
    echo "- Distributed and self-healing"
    echo "- Full control over your data"
    echo "- No cloud storage costs"
else
    echo "❌ Failed to update cloudflare entry"
    exit 1
fi

echo
echo "⚠️  IMPORTANT NOTES:"
echo "=================="
echo "1. Your volsync-s3-template already has the correct repository path"
echo "2. All ExternalSecrets will now pull S3 credentials from cloudflare entry"
echo "3. Existing R2 backups will be replaced with NAS backups"
echo "4. Consider backing up critical data to both local NAS and cloud for redundancy"
