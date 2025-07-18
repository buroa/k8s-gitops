#!/bin/bash

echo "📧 SMTP RELAY SETUP"
echo "==================="
echo "Setting up SMTP relay for cluster email notifications"
echo

echo "This enables your cluster to send email notifications for:"
echo "- Alertmanager alerts"
echo "- Application notifications"
echo "- System monitoring alerts"
echo

echo "📋 SMTP Provider Options:"
echo "========================"
echo "1. Gmail/Google Workspace"
echo "2. Outlook/Office 365"
echo "3. SendGrid"
echo "4. Mailgun"
echo "5. Your own SMTP server"
echo "6. Other provider"
echo

read -p "Choose your SMTP provider (1-6): " PROVIDER_CHOICE

case $PROVIDER_CHOICE in
    1)
        echo
        echo "🔧 GMAIL/GOOGLE WORKSPACE SETUP"
        echo "==============================="
        echo "Requirements:"
        echo "1. Enable 2-factor authentication on your Google account"
        echo "2. Generate an App Password:"
        echo "   - Go to: https://myaccount.google.com/security"
        echo "   - Click 'App passwords'"
        echo "   - Generate password for 'Mail'"
        echo
        SMTP_SERVER="smtp.gmail.com"
        read -p "Enter your Gmail address: " SMTP_USERNAME
        read -s -p "Enter your Gmail App Password: " SMTP_PASSWORD
        ;;
    2)
        echo
        echo "🔧 OUTLOOK/OFFICE 365 SETUP"
        echo "==========================="
        echo "Use your Outlook/Office 365 credentials"
        echo
        SMTP_SERVER="smtp-mail.outlook.com"
        read -p "Enter your Outlook email address: " SMTP_USERNAME
        read -s -p "Enter your Outlook password: " SMTP_PASSWORD
        ;;
    3)
        echo
        echo "🔧 SENDGRID SETUP"
        echo "================="
        echo "Requirements:"
        echo "1. Create SendGrid account at https://sendgrid.com/"
        echo "2. Generate API key in Settings → API Keys"
        echo
        SMTP_SERVER="smtp.sendgrid.net"
        SMTP_USERNAME="apikey"
        read -s -p "Enter your SendGrid API key: " SMTP_PASSWORD
        ;;
    4)
        echo
        echo "🔧 MAILGUN SETUP"
        echo "================"
        echo "Requirements:"
        echo "1. Create Mailgun account at https://mailgun.com/"
        echo "2. Get SMTP credentials from your domain dashboard"
        echo
        SMTP_SERVER="smtp.mailgun.org"
        read -p "Enter your Mailgun SMTP username: " SMTP_USERNAME
        read -s -p "Enter your Mailgun SMTP password: " SMTP_PASSWORD
        ;;
    5)
        echo
        echo "🔧 CUSTOM SMTP SERVER SETUP"
        echo "============================"
        read -p "Enter your SMTP server hostname (e.g., mail.example.com): " SMTP_SERVER
        read -p "Enter your SMTP username: " SMTP_USERNAME
        read -s -p "Enter your SMTP password: " SMTP_PASSWORD
        ;;
    6)
        echo
        echo "🔧 OTHER PROVIDER SETUP"
        echo "======================="
        echo "Contact your email provider for SMTP settings"
        read -p "Enter your SMTP server hostname: " SMTP_SERVER
        read -p "Enter your SMTP username: " SMTP_USERNAME
        read -s -p "Enter your SMTP password: " SMTP_PASSWORD
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo
echo
echo "💾 Creating 1Password entry..."

# Create the smtp-relay entry
op item create \
  --category="Login" \
  --title="smtp-relay" \
  --vault="homelab" \
  --url="$SMTP_SERVER" \
  "username[text]=$SMTP_USERNAME" \
  "password[password]=$SMTP_PASSWORD" \
  "SMTP_RELAY_SERVER[text]=$SMTP_SERVER" \
  "SMTP_RELAY_USERNAME[text]=$SMTP_USERNAME" \
  "SMTP_RELAY_PASSWORD[concealed]=$SMTP_PASSWORD"

if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created 'smtp-relay' entry in 1Password"
    echo
    echo "📧 SMTP Configuration Summary:"
    echo "=============================="
    echo "Server: $SMTP_SERVER"
    echo "Username: $SMTP_USERNAME"
    echo "Password: [stored securely]"
    echo
    echo "🔧 Your cluster can now send email notifications!"
    echo
    echo "📝 Next steps:"
    echo "1. Deploy your SMTP relay service"
    echo "2. Configure Alertmanager to use the SMTP relay"
    echo "3. Test email notifications"
else
    echo "❌ Failed to create 1Password entry"
    echo "Make sure you're signed in: op signin"
    exit 1
fi

echo
echo "⚠️  SECURITY NOTES:"
echo "=================="
echo "- Use app-specific passwords when available"
echo "- Enable 2FA on your email account"
echo "- Monitor for unusual email activity"
echo "- Consider using a dedicated email account for cluster notifications"
