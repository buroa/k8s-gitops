#!/bin/bash

echo "📧 HOTMAIL → SMTP RELAY SETUP"
echo "============================="
echo "Copying your existing hotmail credentials to smtp-relay configuration"
echo

# Get existing hotmail credentials
HOTMAIL_USERNAME=$(op item get hotmail --vault homelab --field username)
HOTMAIL_PASSWORD=$(op item get hotmail --vault homelab --field password --reveal)
SMTP_HOST=$(op item get hotmail --vault homelab --field smtp_host)

echo "Found hotmail credentials:"
echo "- Email: $HOTMAIL_USERNAME"
echo "- SMTP Host: $SMTP_HOST"
echo

# Create smtp-relay entry using hotmail credentials
echo "💾 Creating smtp-relay entry..."

op item create \
  --category="Login" \
  --title="smtp-relay" \
  --vault="homelab" \
  --url="$SMTP_HOST" \
  "username[text]=$HOTMAIL_USERNAME" \
  "password[password]=$HOTMAIL_PASSWORD" \
  "SMTP_RELAY_SERVER[text]=$SMTP_HOST" \
  "SMTP_RELAY_USERNAME[text]=$HOTMAIL_USERNAME" \
  "SMTP_RELAY_PASSWORD[concealed]=$HOTMAIL_PASSWORD"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created 'smtp-relay' entry using your hotmail credentials"
    echo
    echo "📧 SMTP Configuration:"
    echo "====================="
    echo "Server: $SMTP_HOST"
    echo "Username: $HOTMAIL_USERNAME"
    echo "Password: [copied from hotmail entry]"
    echo
    echo "🎉 Your cluster can now send email notifications via Hotmail!"
    echo
    echo "⚠️  SECURITY REMINDER:"
    echo "======================"
    echo "Consider enabling 2FA on your Hotmail account if not already enabled."
    echo "Microsoft may require app passwords for SMTP access in the future."
else
    echo "❌ Failed to create smtp-relay entry"
    exit 1
fi
