#!/bin/bash
set -euo pipefail

# Media Services API Key Bootstrap Script
# Handles the chicken/egg problem of media service API keys

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

# Generate secure API key
generate_api_key() {
    openssl rand -hex 16
}

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | head -c 25
}

# Generate session secret (longer)
generate_session_secret() {
    openssl rand -base64 64 | tr -d "=+/" | head -c 50
}

# Create 1Password item for service (with safety checks)
create_service_item() {
    local service_name="$1"
    local api_key="$2"
    local additional_fields="$3"
    
    # Double-check item doesn't exist (paranoid safety)
    if item_exists "$service_name"; then
        log_warning "SAFETY: Item '$service_name' already exists - skipping creation"
        return 0
    fi
    
    log_info "Creating 1Password item for $service_name..."
    
    # Base item creation using assignment statements
    local create_cmd="op item create --category='API Credential' --title=$service_name --vault=homelab"
    create_cmd="$create_cmd 'API_KEY[concealed]=$api_key'"
    
    # Add additional fields if provided
    if [ -n "$additional_fields" ]; then
        create_cmd="$create_cmd $additional_fields"
    fi
    
    # Execute the command
    log_info "Executing: $create_cmd"
    
    if eval "$create_cmd" &>/dev/null; then
        log_success "Created 1Password item: $service_name"
        
        # Verify creation
        if item_exists "$service_name"; then
            log_success "VERIFIED: Item '$service_name' successfully created"
        else
            log_error "VERIFICATION FAILED: Item '$service_name' not found after creation"
            return 1
        fi
        return 0
    else
        log_error "Failed to create 1Password item: $service_name"
        return 1
    fi
}

# Check if 1Password item exists
item_exists() {
    op item get "$1" --vault homelab &>/dev/null
}

# Safety check - list existing items before proceeding
safety_check() {
    log_info "Safety check - existing 1Password items in homelab vault:"
    
    local services=("radarr" "sonarr" "sabnzbd" "grafana" "atuin" "prowlarr" "autobrr" "gatus")
    local existing_items=()
    
    for service in "${services[@]}"; do
        if item_exists "$service"; then
            existing_items+=("$service")
            log_warning "EXISTING: $service (will NOT be overwritten)"
        else
            log_info "MISSING: $service (will be created)"
        fi
    done
    
    if [ ${#existing_items[@]} -gt 0 ]; then
        log_warning "Found ${#existing_items[@]} existing items that will be preserved"
        log_info "Only missing items will be created"
        
        # Require explicit confirmation if any items exist
        read -p "Continue with creating only missing items? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled by user"
            exit 0
        fi
    else
        log_info "No existing items found - safe to proceed"
    fi
}

# Bootstrap media service secrets
bootstrap_media_secrets() {
    log_info "Bootstrapping media service secrets..."
    
    # Get shared postgres super password for database services
    local POSTGRES_SUPER_PASS=""
    if op item get "cloudnative-pg" --vault homelab &>/dev/null; then
        POSTGRES_SUPER_PASS=$(op item get "cloudnative-pg" --vault homelab --fields POSTGRES_SUPER_PASS --reveal 2>/dev/null || echo "")
    fi
    
    if [ -z "$POSTGRES_SUPER_PASS" ]; then
        log_warning "Could not get POSTGRES_SUPER_PASS from cloudnative-pg item"
        log_info "Database services will need manual password setup"
    fi
    
    # Radarr (Movie management)
    if ! item_exists "radarr"; then
        RADARR_API_KEY=$(generate_api_key)
        RADARR_POSTGRES_USER="radarr"
        RADARR_POSTGRES_PASS=$(generate_password)
        create_service_item "radarr" "$RADARR_API_KEY" \
            "'RADARR_POSTGRES_USER[text]=$RADARR_POSTGRES_USER' 'RADARR_POSTGRES_PASS[concealed]=$RADARR_POSTGRES_PASS' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Radarr secrets already exist"
    fi
    
    # Sonarr (TV management)
    if ! item_exists "sonarr"; then
        SONARR_API_KEY=$(generate_api_key)
        SONARR_POSTGRES_USER="sonarr"
        SONARR_POSTGRES_PASS=$(generate_password)
        create_service_item "sonarr" "$SONARR_API_KEY" \
            "'SONARR_POSTGRES_USER[text]=$SONARR_POSTGRES_USER' 'SONARR_POSTGRES_PASS[concealed]=$SONARR_POSTGRES_PASS' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Sonarr secrets already exist"
    fi
    
    # SABnzbd (Download client)
    if ! item_exists "sabnzbd"; then
        SABNZBD_API_KEY=$(generate_api_key)
        SABNZBD_NZB_KEY=$(generate_api_key)
        create_service_item "sabnzbd" "$SABNZBD_API_KEY" \
            "'NZB_KEY[concealed]=$SABNZBD_NZB_KEY'"
    else
        log_info "SABnzbd secrets already exist"
    fi
    
    # Grafana (Monitoring)
    if ! item_exists "grafana"; then
        GRAFANA_ADMIN_USER="admin"
        GRAFANA_ADMIN_PASSWORD=$(generate_password)
        create_service_item "grafana" "$(generate_api_key)" \
            "'ADMIN_USER[text]=$GRAFANA_ADMIN_USER' 'ADMIN_PASSWORD[concealed]=$GRAFANA_ADMIN_PASSWORD'"
    else
        log_info "Grafana secrets already exist"
    fi
    
    # Atuin (shell history sync)
    if ! item_exists "atuin"; then
        ATUIN_POSTGRES_USER="atuin"
        ATUIN_POSTGRES_PASS=$(generate_password)
        create_service_item "atuin" "$(generate_api_key)" \
            "'ATUIN_POSTGRES_USER[text]=$ATUIN_POSTGRES_USER' 'ATUIN_POSTGRES_PASS[concealed]=$ATUIN_POSTGRES_PASS' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Atuin secrets already exist"
    fi
    
    # Prowlarr (indexer manager)
    if ! item_exists "prowlarr"; then
        PROWLARR_API_KEY=$(generate_api_key)
        PROWLARR_POSTGRES_USER="prowlarr"
        PROWLARR_POSTGRES_PASS=$(generate_password)
        create_service_item "prowlarr" "$PROWLARR_API_KEY" \
            "'PROWLARR_POSTGRES_USER[text]=$PROWLARR_POSTGRES_USER' 'PROWLARR_POSTGRES_PASS[concealed]=$PROWLARR_POSTGRES_PASS' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Prowlarr secrets already exist"
    fi
    
    # Autobrr (torrent automation)
    if ! item_exists "autobrr"; then
        AUTOBRR_POSTGRES_USER="autobrr"
        AUTOBRR_POSTGRES_PASS=$(generate_password)
        AUTOBRR_SESSION_SECRET=$(generate_session_secret)
        create_service_item "autobrr" "$(generate_api_key)" \
            "'AUTOBRR_POSTGRES_USER[text]=$AUTOBRR_POSTGRES_USER' 'AUTOBRR_POSTGRES_PASS[concealed]=$AUTOBRR_POSTGRES_PASS' 'AUTOBRR_SESSION_SECRET[concealed]=$AUTOBRR_SESSION_SECRET' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Autobrr secrets already exist"
    fi
    
    # Gatus (status page)
    if ! item_exists "gatus"; then
        GATUS_POSTGRES_USER="gatus"
        GATUS_POSTGRES_PASS=$(generate_password)
        create_service_item "gatus" "$(generate_api_key)" \
            "'GATUS_POSTGRES_USER[text]=$GATUS_POSTGRES_USER' 'GATUS_POSTGRES_PASS[concealed]=$GATUS_POSTGRES_PASS' 'POSTGRES_SUPER_PASS[concealed]=$POSTGRES_SUPER_PASS'"
    else
        log_info "Gatus secrets already exist"
    fi
}

# Force sync external secrets after creation
sync_external_secrets() {
    log_info "Force syncing external secrets..."
    
    local services=("recyclarr" "sabnzbd" "grafana" "atuin" "prowlarr" "autobrr" "sonarr" "radarr" "gatus")
    local namespaces=("media media observability default media media media media observability")
    
    # Convert to arrays
    read -r -a service_array <<< "${services[@]}"
    read -r -a namespace_array <<< "$namespaces"
    
    for i in "${!service_array[@]}"; do
        local service="${service_array[$i]}"
        local namespace="${namespace_array[$i]}"
        
        if kubectl get externalsecret "$service" -n "$namespace" &>/dev/null; then
            log_info "Force syncing $service external secret..."
            kubectl annotate externalsecret "$service" -n "$namespace" \
                force-sync="$(date +%s)" --overwrite
        fi
    done
}

# Main execution
main() {
    log_info "Starting media services secret bootstrap..."
    
    # Check if logged into 1Password
    if ! op user get --me &>/dev/null; then
        log_error "Not logged into 1Password CLI. Run: op signin"
        exit 1
    fi
    
    # Check kubectl access
    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot access Kubernetes cluster"
        exit 1
    fi
    
    # SAFETY: Check existing items before proceeding
    safety_check
    
    bootstrap_media_secrets
    sync_external_secrets
    
    log_success "Media services secret bootstrap complete!"
    log_info "Next steps:"
    log_info "  1. Wait for external secrets to sync (30-60 seconds)"
    log_info "  2. Check pod status: kubectl get pods -n media"
    log_info "  3. Access services via their web interfaces to complete setup"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi