#!/bin/bash

echo "🧹 SEAWEEDFS → CLOUDFLARE CLEANUP"
echo "=================================="
echo "Cleaning up old S3 fields from cloudflare 1Password entry"
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

echo "🔍 Checking current cloudflare entry..."

# Check what S3 fields exist in cloudflare entry
S3_FIELDS=$(op item get cloudflare --vault homelab --format json 2>/dev/null | jq -r '.fields[] | select(.label | startswith("S3_")) | .label' 2>/dev/null)

if [[ -n "$S3_FIELDS" ]]; then
    echo "📋 Found S3 fields in cloudflare entry:"
    echo "$S3_FIELDS" | sed 's/^/   - /'
    echo

    echo "⚠️  NOTE: 1Password CLI doesn't support field deletion directly."
    echo "🔧 Manual cleanup required:"
    echo
    echo "1. Open 1Password app or web interface"
    echo "2. Navigate to homelab vault → cloudflare entry"
    echo "3. Edit the entry and remove these fields:"
    echo "$S3_FIELDS" | sed 's/^/   - /'
    echo
    echo "✅ The seaweedfs entry now contains all S3 credentials"
    echo "🔄 Your cluster should reference the 'seaweedfs' entry instead"

    # Create a temporary script to show the user what to do
    cat << 'EOF'

📝 Alternative: Use this 1Password CLI command to recreate cloudflare without S3 fields:

   # Backup current cloudflare entry first
   op item get cloudflare --vault homelab --format json > cloudflare-backup.json

   # Then manually recreate without S3 fields, or use the 1Password interface

🎯 VERIFICATION: After cleanup, this should return nothing:
   op item get cloudflare --vault homelab --format json | jq '.fields[] | select(.label | startswith("S3_"))'

EOF
else
    echo "✅ No S3 fields found in cloudflare entry (already clean)"
    echo "🎉 Cleanup complete!"
fi

echo
echo "📊 SUMMARY:"
echo "==========="
echo "• SeaweedFS credentials: seaweedfs entry (✅ active)"
echo "• Cloudflare credentials: cloudflare entry (should not have S3 fields)"
echo "• VolSync configuration: uses seaweedfs entry directly"
echo
echo "🔗 Next steps:"
echo "   • Ensure your cluster uses the seaweedfs volsync component"
echo "   • Run: kubectl annotate externalsecrets --all external-secrets.io/force-sync=\$(date +%s) -A"
