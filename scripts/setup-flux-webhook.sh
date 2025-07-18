#!/bin/bash

echo "🔧 FLUX WEBHOOK TOKEN SETUP"
echo "============================"
echo "Setting up GitHub webhook token for Flux GitOps automation"
echo

echo "This webhook token allows GitHub to notify your Flux instance of repository changes,"
echo "enabling faster reconciliation instead of waiting for the polling interval."
echo

echo "📋 What you need:"
echo "1. A secure random token (we'll generate one)"
echo "2. To configure this token in your GitHub repository webhook settings"
echo

# Generate a secure webhook token
WEBHOOK_TOKEN=$(openssl rand -hex 32)

echo "Generated webhook token: $WEBHOOK_TOKEN"
echo

# Check if flux entry already exists
if op item get flux --vault homelab >/dev/null 2>&1; then
    echo "🔄 Flux entry already exists. Updating with webhook token..."

    # Add webhook token to existing entry
    op item edit flux --vault homelab "FLUX_GITHUB_WEBHOOK_TOKEN[concealed]=$WEBHOOK_TOKEN"

    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully updated existing 'flux' entry with webhook token"
    else
        echo "❌ Failed to update existing flux entry"
        exit 1
    fi
else
    echo "🆕 Creating new flux entry with webhook token..."

    # Create new flux entry
    op item create \
      --category="Secure Note" \
      --title="flux" \
      --vault="homelab" \
      "FLUX_GITHUB_WEBHOOK_TOKEN[concealed]=$WEBHOOK_TOKEN"

    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully created 'flux' entry with webhook token"
    else
        echo "❌ Failed to create flux entry"
        exit 1
    fi
fi

echo
echo "🎯 NEXT STEPS:"
echo "=============="
echo
echo "1. Your Flux ExternalSecret will now be able to pull the webhook token"
echo
echo "2. Configure GitHub webhook in your repository:"
echo "   a. Go to: https://github.com/cpritchett/home-ops/settings/hooks"
echo "   b. Click 'Add webhook'"
echo "   c. Set Payload URL: https://flux-webhook.hypyr.space/"
echo "   d. Set Content type: application/json"
echo "   e. Set Secret: $WEBHOOK_TOKEN"
echo "   f. Select events: 'Just the push event'"
echo "   g. Ensure 'Active' is checked"
echo "   h. Click 'Add webhook'"
echo
echo "3. Test the webhook:"
echo "   - Make a commit to your repository"
echo "   - Check that Flux reconciles faster than the normal polling interval"
echo
echo "📝 Webhook token stored securely in 1Password vault 'homelab'"
echo "🔐 Token: $WEBHOOK_TOKEN (copy this for GitHub webhook configuration)"
