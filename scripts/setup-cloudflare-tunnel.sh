#!/bin/bash
set -euo pipefail

# Cloudflare Tunnel Setup Script
# Sets up tunnel configuration for external access to homelab services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in op cloudflared jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install missing tools:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                op)
                    echo "  - 1Password CLI: https://developer.1password.com/docs/cli/get-started/"
                    ;;
                cloudflared)
                    echo "  - Cloudflared: mise use -g cloudflared"
                    ;;
                jq)
                    echo "  - jq: mise use -g jq"
                    ;;
            esac
        done
        exit 1
    fi
}

# Get or create Cloudflare tunnel
setup_tunnel() {
    log_info "Setting up Cloudflare tunnel..."
    
    # Check if we already have tunnel info in 1Password
    if op item get cloudflare --field CLOUDFLARE_TUNNEL_ID --vault homelab &>/dev/null; then
        TUNNEL_ID=$(op item get cloudflare --field CLOUDFLARE_TUNNEL_ID --vault homelab --reveal)
        log_info "Found existing tunnel ID: $TUNNEL_ID"
    else
        log_info "Creating new Cloudflare tunnel..."
        
        # Get Cloudflare API token for tunnel creation
        CF_API_TOKEN=$(op item get cloudflare --field CLOUDFLARE_API_TOKEN --vault homelab --reveal)
        export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
        
        # Create tunnel
        TUNNEL_NAME="homeops-$(date +%Y%m%d-%H%M%S)"
        log_info "Creating tunnel: $TUNNEL_NAME"
        
        # Create tunnel and capture output
        if TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1); then
            log_info "Tunnel creation output: $TUNNEL_OUTPUT"
            
            # Extract tunnel ID from credentials file path (more reliable than parsing output)
            TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -o '[a-f0-9-]\{36\}' | head -1)
            
            if [ -z "$TUNNEL_ID" ]; then
                log_error "Could not extract tunnel ID from output"
                exit 1
            fi
            
            # Get tunnel secret from credentials file
            CRED_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
            if [ -f "$CRED_FILE" ]; then
                TUNNEL_SECRET=$(jq -r '.TunnelSecret' "$CRED_FILE")
            else
                log_error "Credentials file not found: $CRED_FILE"
                exit 1
            fi
        else
            log_error "Failed to create tunnel: $TUNNEL_OUTPUT"
            exit 1
        fi
        
        log_success "Created tunnel: $TUNNEL_NAME (ID: $TUNNEL_ID)"
        
        # Get account ID from API
        ACCOUNT_ID=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
                         -H "Content-Type: application/json" \
                         "https://api.cloudflare.com/client/v4/accounts" | \
                    jq -r '.result[0].id // empty')
        
        if [ -z "$ACCOUNT_ID" ]; then
            log_error "Could not determine Cloudflare Account ID"
            exit 1
        fi
        
        log_info "Found Cloudflare Account ID: $ACCOUNT_ID"
        
        # Update 1Password with tunnel configuration
        log_info "Storing tunnel configuration in 1Password..."
        op item edit cloudflare --vault homelab \
            "CLOUDFLARE_ACCOUNT_ID[text]=$ACCOUNT_ID" \
            "CLOUDFLARE_TUNNEL_ID[text]=$TUNNEL_ID" \
            "CLOUDFLARE_TUNNEL_SECRET[text]=$TUNNEL_SECRET"
        
        log_success "Tunnel configuration stored in 1Password"
    fi
}

# Configure DNS for tunnel
setup_dns() {
    log_info "Setting up DNS configuration..."
    
    # This would typically create CNAME records pointing to the tunnel
    # For now, just show what needs to be done
    TUNNEL_ID=$(op item get cloudflare --field CLOUDFLARE_TUNNEL_ID --vault homelab --reveal)
    
    log_info "Tunnel ready for DNS configuration:"
    log_info "  Tunnel ID: $TUNNEL_ID"
    log_info "  CNAME target: $TUNNEL_ID.cfargotunnel.com"
    log_warning "Configure DNS records manually in Cloudflare dashboard or via external-dns"
}

# Main execution
main() {
    log_info "Starting Cloudflare tunnel setup..."
    
    check_dependencies
    
    # Check if logged into 1Password
    if ! op user get --me &>/dev/null; then
        log_error "Not logged into 1Password CLI. Run: op signin"
        exit 1
    fi
    
    setup_tunnel
    setup_dns
    
    log_success "Cloudflare tunnel setup complete!"
    log_info "Next steps:"
    log_info "  1. Verify tunnel configuration: cloudflared tunnel info \$TUNNEL_ID"
    log_info "  2. Configure ingress rules for external services"
    log_info "  3. Restart cloudflared deployment: kubectl rollout restart deployment/cloudflared -n networking"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi