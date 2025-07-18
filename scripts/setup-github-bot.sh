#!/bin/bash

echo "GitHub Bot App Setup for Repository Automation"
echo "=============================================="
echo

# Collect GitHub Bot App information
read -p "Enter your Bot GitHub App ID: " BOT_APP_ID
read -p "Enter the path to your Bot private key (.pem file): " BOT_PRIVATE_KEY_PATH

echo
echo "Validating inputs..."

# Validate App ID is numeric
if ! [[ "$BOT_APP_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Bot App ID must be numeric"
    exit 1
fi

# Validate private key file exists
if [[ ! -f "$BOT_PRIVATE_KEY_PATH" ]]; then
    echo "Error: Bot private key file not found at $BOT_PRIVATE_KEY_PATH"
    exit 1
fi

# Read the private key content
BOT_PRIVATE_KEY_CONTENT=$(cat "$BOT_PRIVATE_KEY_PATH")

echo
echo "Creating 1Password entry for Bot App..."

# Create the 1Password entry for Bot App
op item create \
  --category="Secure Note" \
  --title="github-bot" \
  --vault="homelab" \
  "BOT_APP_ID[text]=$BOT_APP_ID" \
  "BOT_APP_PRIVATE_KEY[concealed]=$BOT_PRIVATE_KEY_CONTENT"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created 1Password entry 'github-bot' in vault 'homelab'"
    echo
    echo "Summary:"
    echo "- Bot App ID: $BOT_APP_ID"
    echo "- Bot Private key: Stored securely"
    echo
    echo "Next steps:"
    echo "1. Go to your GitHub repository settings"
    echo "2. Navigate to Secrets and variables → Actions"
    echo "3. Add these repository secrets:"
    echo "   - BOT_APP_ID: $BOT_APP_ID"
    echo "   - BOT_APP_PRIVATE_KEY: (copy from 1Password)"
    echo
    echo "Or run these commands:"
    echo "gh secret set BOT_APP_ID --repo cpritchett/home-ops --body '$BOT_APP_ID'"
    echo "gh secret set BOT_APP_PRIVATE_KEY --repo cpritchett/home-ops < '$BOT_PRIVATE_KEY_PATH'"
else
    echo "❌ Failed to create 1Password entry"
    echo "Make sure you're signed in to 1Password CLI with: op signin"
    exit 1
fi
