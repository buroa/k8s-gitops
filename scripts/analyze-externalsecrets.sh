#!/bin/bash

echo "=== 1Password ExternalSecret Analysis ==="
echo "========================================="
echo

# Find all unique 1Password keys referenced in ExternalSecrets
echo "📋 Analyzing all ExternalSecret configurations..."
echo

# Extract unique keys
KEYS=$(find kubernetes -name "externalsecret.yaml" -type f -exec grep -h "key:" {} \; | grep -v "github_app\|private_key\|API" | sed 's/.*key: *//' | sort -u)

echo "🔑 1Password entries referenced in ExternalSecrets:"
echo "================================================="

for key in $KEYS; do
    echo "- $key"
done

echo
echo "📊 Analysis by Category:"
echo "======================="

echo
echo "🏠 INFRASTRUCTURE & NETWORKING:"
echo "  - cloudflare          (DNS, Tunnels, R2 storage)"
echo "  - tailscale           (VPN mesh networking)"
echo "  - unifi               (Network equipment API)"
echo "  - smtp-relay          (Email notifications)"

echo
echo "🗄️  DATABASE:"
echo "  - cloudnative-pg      (PostgreSQL operator - auto-generated)"

echo
echo "📱 MEDIA STACK:"
echo "  - radarr              (Movie management - generates API key)"
echo "  - sonarr              (TV management - generates API key)"
echo "  - prowlarr            (Indexer management - generates API key)"
echo "  - sabnzbd             (Download client - generates API keys)"
echo "  - autobrr             (Release automation - generates API key)"
echo "  - cross-seed          (Cross-seeding - generates API key)"

echo
echo "📊 MONITORING:"
echo "  - grafana             (Dashboard - generates admin password)"
echo "  - alertmanager        (Alert routing - requires external API keys)"
echo "  - gatus               (Status monitoring - generates admin password)"

echo
echo "🔧 AUTOMATION:"
echo "  - actions-runner      (GitHub Actions - manual setup ✅)"
echo "  - flux                (GitOps - webhook token)"
echo "  - atuin               (Shell history - generates admin password)"

echo
echo "🔐 SECURITY:"
echo "  - volsync-restic-template (Backup encryption - manual setup)"

echo
echo "==============================================="
echo "🎯 SETUP PRIORITY RECOMMENDATIONS:"
echo "==============================================="

echo
echo "✅ COMPLETED:"
echo "  - actions-runner (manual GitHub App setup)"

echo
echo "🔴 HIGH PRIORITY (External APIs - Manual Setup Required):"
echo "  - cloudflare      → API token from Cloudflare dashboard"
echo "  - tailscale       → Auth key from Tailscale admin console"
echo "  - unifi           → API key from UniFi controller"
echo "  - alertmanager    → Pushover/notification service API keys"

echo
echo "🟡 MEDIUM PRIORITY (App-Generated - Set After Deploy):"
echo "  - radarr, sonarr, prowlarr → API keys from app settings"
echo "  - sabnzbd, autobrr, cross-seed → API keys from app settings"
echo "  - grafana, gatus, atuin → Admin passwords (set during install)"

echo
echo "🟢 LOW PRIORITY (Auto-Generated):"
echo "  - cloudnative-pg  → PostgreSQL credentials (auto-generated)"
echo "  - flux            → Webhook tokens (can be generated)"

echo
echo "🔒 SPECIAL CASES:"
echo "  - volsync-restic-template → Backup encryption passphrase"
echo "  - smtp-relay      → Email service credentials"

echo
echo "==============================================="
echo "📝 NEXT STEPS:"
echo "==============================================="
echo "1. Create setup scripts for high-priority external APIs"
echo "2. Document app-generated API key setup process"
echo "3. Set up backup encryption passphrase"
echo "4. Configure email relay service"
