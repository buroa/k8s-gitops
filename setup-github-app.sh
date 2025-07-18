#!/bin/bash

echo "GitHub App Setup for Actions Runner Controller"
echo "============================================="
echo

# Collect GitHub App information
read -p "Enter your GitHub App ID: " GITHUB_APP_ID
read -p "Enter the path to your downloaded private key (.pem file): " PRIVATE_KEY_PATH
read -p "Enter your GitHub App Installation ID: " GITHUB_INSTALLATION_ID

echo
echo "Validating inputs..."

# Validate App ID is numeric
if ! [[ "$GITHUB_APP_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: App ID must be numeric"
    exit 1
fi

# Validate private key file exists
if [[ ! -f "$PRIVATE_KEY_PATH" ]]; then
    echo "Error: Private key file not found at $PRIVATE_KEY_PATH"
    exit 1
fi

# Validate Installation ID is numeric
if ! [[ "$GITHUB_INSTALLATION_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Installation ID must be numeric"
    exit 1
fi

# Read the private key content
PRIVATE_KEY_CONTENT=$(cat "$PRIVATE_KEY_PATH")

echo
echo "Creating 1Password entry..."

# Create the 1Password entry
op item create \
  --category="Secure Note" \
  --title="actions-runner" \
  --vault="homelab" \
  --field="label=ACTION_RUNNER_GITHUB_APP_ID,type=text,value=$GITHUB_APP_ID" \
  --field="label=ACTION_RUNNER_GITHUB_INSTALLATION_ID,type=text,value=$GITHUB_INSTALLATION_ID" \
  --field="label=ACTION_RUNNER_GITHUB_PRIVATE_KEY,type=concealed,value=$PRIVATE_KEY_CONTENT"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created 1Password entry 'actions-runner' in vault 'homelab'"
    echo
    echo "Summary:"
    echo "- App ID: $GITHUB_APP_ID"
    echo "- Installation ID: $GITHUB_INSTALLATION_ID"
    echo "- Private key: Stored securely"
    echo
    echo "Your ExternalSecret should now be able to pull these values!"
else
    echo "❌ Failed to create 1Password entry"
    echo "Make sure you're signed in to 1Password CLI with: op signin"
    exit 1
fi
