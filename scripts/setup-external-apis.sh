#!/bin/bash

echo "🔴 HIGH PRIORITY: External API Setup for 1Password"
echo "================================================="
echo
echo "This script will help you set up the critical external API credentials"
echo "that need to be obtained from external services before your cluster can function."
echo

# Cloudflare API Token
echo "1️⃣  CLOUDFLARE API TOKEN"
echo "========================"
echo "Required for: DNS management, Cloudflare Tunnel, R2 storage"
echo "How to get:"
echo "  1. Go to https://dash.cloudflare.com/profile/api-tokens"
echo "  2. Click 'Create Token' → 'Get started' with Custom token"
echo "  3. Set these permissions:"
echo "     - Zone:Zone:Read (for all zones)"
echo "     - Zone:DNS:Edit (for all zones)"
echo "     - Account:Cloudflare Tunnel:Edit"
echo "     - Account:Account Settings:Read"
echo "     - Zone:Zone Settings:Read"
echo "  4. For R2 storage, also add:"
echo "     - Account:R2 Storage:Edit"
echo "  5. Set Account Resources: Include → Your account"
echo "  6. Set Zone Resources: Include → All zones (or specific zone)"
echo "  7. Copy the token"
echo
read -p "Enter your Cloudflare API token: " CLOUDFLARE_TOKEN
echo

# Tailscale Auth Key
echo "2️⃣  TAILSCALE AUTH KEY"
echo "======================"
echo "Required for: VPN mesh networking"
echo "How to get:"
echo "  1. Go to https://login.tailscale.com/admin/settings/keys"
echo "  2. Click 'Generate auth key'"
echo "  3. Set expiration and enable 'Reusable' and 'Ephemeral'"
echo "  4. Copy the key (starts with tskey-auth-)"
echo
read -p "Enter your Tailscale auth key: " TAILSCALE_KEY
echo

# UniFi API Details
echo "3️⃣  UNIFI CONTROLLER"
echo "==================="
echo "Required for: Network monitoring and device management"
echo "How to get:"
echo "  1. Log into your UniFi controller"
echo "  2. Go to Settings → Admins"
echo "  3. Create a new admin user for API access"
echo "  4. Note your controller URL and credentials"
echo
read -p "Enter your UniFi controller URL (e.g. https://unifi.local:8443): " UNIFI_URL
read -p "Enter your UniFi username: " UNIFI_USER
read -s -p "Enter your UniFi password: " UNIFI_PASS
echo
echo

# Pushover for Alerts
echo "4️⃣  ALERTMANAGER / PUSHOVER"
echo "==========================="
echo "Required for: Mobile push notifications for alerts"
echo "How to get:"
echo "  1. Go to https://pushover.net/"
echo "  2. Create account and note your User Key"
echo "  3. Create an application and note the API Token"
echo
read -p "Enter your Pushover User Key: " PUSHOVER_USER
read -p "Enter your Pushover API Token: " PUSHOVER_TOKEN
echo

# Optional: Heartbeat URL
echo "5️⃣  HEALTHCHECKS.IO (Optional)"
echo "=============================="
echo "Required for: Dead man's switch monitoring"
echo "How to get:"
echo "  1. Go to https://healthchecks.io/"
echo "  2. Create account and add a check"
echo "  3. Copy the ping URL"
echo
read -p "Enter your Healthchecks.io URL (or press Enter to skip): " HEARTBEAT_URL
echo

echo "💾 Creating 1Password entries..."
echo "================================"

# Create Cloudflare entry
op item create \
  --category="API Credential" \
  --title="cloudflare" \
  --vault="homelab" \
  "CF_API_TOKEN[concealed]=$CLOUDFLARE_TOKEN"

# Create Tailscale entry
op item create \
  --category="API Credential" \
  --title="tailscale" \
  --vault="homelab" \
  "TS_AUTH_KEY[concealed]=$TAILSCALE_KEY"

# Create UniFi entry
op item create \
  --category="Login" \
  --title="unifi" \
  --vault="homelab" \
  --url="$UNIFI_URL" \
  "username[text]=$UNIFI_USER" \
  "password[password]=$UNIFI_PASS" \
  "UNIFI_API_KEY[concealed]=$UNIFI_PASS"

# Create Alertmanager entry
ALERTMANAGER_FIELDS="ALERTMANAGER_PUSHOVER_APP_TOKEN[concealed]=$PUSHOVER_TOKEN"
ALERTMANAGER_FIELDS+=" ALERTMANAGER_PUSHOVER_USER_KEY[concealed]=$PUSHOVER_USER"

if [[ -n "$HEARTBEAT_URL" ]]; then
    ALERTMANAGER_FIELDS+=" ALERTMANAGER_HEARTBEAT_URL[text]=$HEARTBEAT_URL"
fi

op item create \
  --category="Secure Note" \
  --title="alertmanager" \
  --vault="homelab" \
  $ALERTMANAGER_FIELDS

echo
echo "✅ SUCCESS! Created 1Password entries:"
echo "  - cloudflare"
echo "  - tailscale"
echo "  - unifi"
echo "  - alertmanager"
echo
echo "🔐 These entries contain the API credentials your cluster needs to function."
echo "🚀 Your ExternalSecrets should now be able to pull these values!"
echo
echo "Next: Run the medium-priority setup after deploying your applications."
