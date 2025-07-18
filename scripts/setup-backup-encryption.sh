#!/bin/bash

echo "🔒 BACKUP ENCRYPTION SETUP"
echo "=========================="
echo "Setting up volsync-restic-template for encrypted backups"
echo

echo "This will create a strong encryption passphrase for your backup system."
echo "⚠️  Store this passphrase safely - you'll need it to restore backups!"
echo

# Generate a strong passphrase
PASSPHRASE=$(openssl rand -base64 32)

echo "Generated encryption passphrase: $PASSPHRASE"
echo

# Confirm with user
read -p "Use this generated passphrase? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    read -p "Enter your own backup encryption passphrase: " PASSPHRASE
fi

echo
echo "💾 Creating 1Password entry for backup encryption..."

# Create the volsync-restic-template entry
op item create \
  --category="Secure Note" \
  --title="volsync-restic-template" \
  --vault="homelab" \
  "RESTIC_PASSWORD[concealed]=$PASSPHRASE"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created 'volsync-restic-template' entry in 1Password"
    echo
    echo "🔐 Your backup encryption is now configured!"
    echo "📝 The passphrase is safely stored in 1Password vault 'homelab'"
    echo
    echo "⚠️  IMPORTANT: Keep a separate backup of this passphrase!"
    echo "    Without it, your backups cannot be restored."
else
    echo "❌ Failed to create 1Password entry"
    echo "Make sure you're signed in: op signin"
fi
