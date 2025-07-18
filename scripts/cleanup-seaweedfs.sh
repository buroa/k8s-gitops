#!/bin/bash

echo "🧹 SEAWEEDFS CLEANUP UTILITY"
echo "============================"
echo "This script helps clean up SeaweedFS deployment and reset configuration"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "ok")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warn")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Show current status
echo "🔍 Current SeaweedFS status:"
echo

# Check container status
print_status "info" "Checking for SeaweedFS containers..."
if ssh cpritchett@razzia.hypyr.space "docker ps --filter 'ancestor=chrislusf/seaweedfs' --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null; then
    echo
else
    print_status "info" "No running SeaweedFS containers found (or SSH failed)"
fi

# Check for stopped containers
print_status "info" "Checking for stopped SeaweedFS containers..."
if ssh cpritchett@razzia.hypyr.space "docker ps -a --filter 'ancestor=chrislusf/seaweedfs' --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null; then
    echo
else
    print_status "info" "No SeaweedFS containers found"
fi

echo
echo "🔧 Cleanup Options:"
echo "=================="
echo "1. Stop SeaweedFS containers"
echo "2. Remove SeaweedFS containers"
echo "3. Remove SeaweedFS images"
echo "4. Clean SeaweedFS data (⚠️  DESTRUCTIVE)"
echo "5. Reset 1Password S3 configuration"
echo "6. Full cleanup (all of the above)"
echo "7. Exit"
echo

read -p "Choose an option (1-7): " choice

case $choice in
    1)
        echo "🛑 Stopping SeaweedFS containers..."
        ssh cpritchett@razzia.hypyr.space "docker stop \$(docker ps -q --filter 'ancestor=chrislusf/seaweedfs') 2>/dev/null || echo 'No running containers to stop'"
        print_status "ok" "Stop command executed"
        ;;
    2)
        echo "🗑️  Removing SeaweedFS containers..."
        ssh cpritchett@razzia.hypyr.space "docker rm \$(docker ps -aq --filter 'ancestor=chrislusf/seaweedfs') 2>/dev/null || echo 'No containers to remove'"
        print_status "ok" "Remove command executed"
        ;;
    3)
        echo "🖼️  Removing SeaweedFS images..."
        ssh cpritchett@razzia.hypyr.space "docker rmi chrislusf/seaweedfs:latest 2>/dev/null || echo 'No images to remove'"
        print_status "ok" "Image removal command executed"
        ;;
    4)
        echo "⚠️  WARNING: This will permanently delete all SeaweedFS data!"
        read -p "Are you sure? Type 'DELETE' to confirm: " confirm
        if [[ "$confirm" == "DELETE" ]]; then
            echo "🗄️  Removing SeaweedFS data directory..."
            ssh cpritchett@razzia.hypyr.space "sudo rm -rf /volume1/docker/seaweedfs/ 2>/dev/null || echo 'Data directory already removed or permission denied'"
            print_status "warn" "Data removal command executed"
        else
            print_status "info" "Data removal cancelled"
        fi
        ;;
    5)
        echo "🔐 Resetting 1Password S3 configuration..."
        if command -v op >/dev/null 2>&1; then
            if op account list >/dev/null 2>&1; then
                echo "Current S3 endpoint: $(op item get cloudflare --vault homelab --field S3_ENDPOINT 2>/dev/null || echo 'Not set')"
                read -p "Reset to Cloudflare R2? (y/N): " reset_1p
                if [[ "$reset_1p" =~ ^[Yy]$ ]]; then
                    # You would need to set these to your original Cloudflare R2 values
                    echo "ℹ️  Note: You'll need to manually set your Cloudflare R2 credentials"
                    echo "   Use: op item edit cloudflare --vault homelab"
                    print_status "info" "1Password reset instructions provided"
                fi
            else
                print_status "warn" "1Password CLI not signed in"
            fi
        else
            print_status "warn" "1Password CLI not found"
        fi
        ;;
    6)
        echo "🧨 FULL CLEANUP - This will remove everything!"
        read -p "Are you absolutely sure? Type 'NUKE' to confirm: " confirm
        if [[ "$confirm" == "NUKE" ]]; then
            echo "🛑 Stopping containers..."
            ssh cpritchett@razzia.hypyr.space "docker stop \$(docker ps -q --filter 'ancestor=chrislusf/seaweedfs') 2>/dev/null || true"

            echo "🗑️  Removing containers..."
            ssh cpritchett@razzia.hypyr.space "docker rm \$(docker ps -aq --filter 'ancestor=chrislusf/seaweedfs') 2>/dev/null || true"

            echo "🖼️  Removing images..."
            ssh cpritchett@razzia.hypyr.space "docker rmi chrislusf/seaweedfs:latest 2>/dev/null || true"

            echo "🗄️  Removing data directory..."
            ssh cpritchett@razzia.hypyr.space "sudo rm -rf /volume1/docker/seaweedfs/ 2>/dev/null || true"

            print_status "warn" "Full cleanup completed"
            echo
            print_status "info" "To complete cleanup:"
            echo "   1. Remove reverse proxy rules in DSM"
            echo "   2. Remove DNS records in UniFi"
            echo "   3. Reset 1Password S3 configuration manually"
        else
            print_status "info" "Full cleanup cancelled"
        fi
        ;;
    7)
        print_status "info" "Exiting cleanup utility"
        exit 0
        ;;
    *)
        print_status "error" "Invalid option"
        exit 1
        ;;
esac

echo
echo "✨ Cleanup operation completed!"
echo
echo "🔄 After cleanup, you can:"
echo "   • Redeploy SeaweedFS using the setup guide"
echo "   • Run: ./scripts/setup-seaweedfs-k8s-integration.sh"
echo "   • Check status: ./scripts/check-seaweedfs-status.sh"
