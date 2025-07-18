#!/bin/bash

echo "🌊 SEAWEEDFS STATUS CHECKER"
echo "=========================="
echo "Checking SeaweedFS deployment and S3 functionality"
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

# Check if we can reach the NAS
echo "🔍 Checking SeaweedFS deployment..."

if ping -c 1 razzia.hypyr.space >/dev/null 2>&1; then
    print_status "ok" "NAS (razzia.hypyr.space) is reachable"
else
    print_status "error" "Cannot reach NAS (razzia.hypyr.space)"
    exit 1
fi

# Check container status via SSH
echo
echo "🐳 Checking Docker container status..."

if ssh -o ConnectTimeout=5 cpritchett@razzia.hypyr.space "docker ps --filter 'ancestor=chrislusf/seaweedfs' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null; then
    print_status "ok" "SeaweedFS container found and accessible via SSH"
else
    print_status "warn" "Cannot check container status via SSH - trying direct API tests"
fi

echo
echo "🌐 Testing S3 API endpoints..."

# Test S3 API
if curl -sI https://s3.hypyr.space --connect-timeout 5 >/dev/null 2>&1; then
    print_status "ok" "S3 API (https://s3.hypyr.space) is responding"
else
    print_status "error" "S3 API endpoint is not responding"
fi

# Test Web UI
if curl -sI https://s3-web.hypyr.space --connect-timeout 5 >/dev/null 2>&1; then
    print_status "ok" "Web UI (https://s3-web.hypyr.space) is responding"
else
    print_status "error" "Web UI endpoint is not responding"
fi

# Test direct ports (if accessible)
echo
echo "🔌 Testing direct port connectivity..."

if nc -z razzia.hypyr.space 8333 2>/dev/null; then
    print_status "ok" "Direct S3 port (8333) is accessible"
else
    print_status "warn" "Direct S3 port (8333) is not accessible (may be firewalled)"
fi

if nc -z razzia.hypyr.space 9333 2>/dev/null; then
    print_status "ok" "Direct admin port (9333) is accessible"
else
    print_status "warn" "Direct admin port (9333) is not accessible (may be firewalled)"
fi

# Check 1Password configuration
echo
echo "🔐 Checking 1Password S3 configuration..."

if command -v op >/dev/null 2>&1; then
    if op account list >/dev/null 2>&1; then
        S3_ENDPOINT=$(op item get cloudflare --vault homelab --field S3_ENDPOINT 2>/dev/null || echo "")
        S3_ACCESS_KEY=$(op item get cloudflare --vault homelab --field S3_ACCESS_KEY_ID 2>/dev/null || echo "")

        if [[ "$S3_ENDPOINT" == "https://s3.hypyr.space" ]]; then
            print_status "ok" "1Password S3 endpoint correctly set to SeaweedFS"
        else
            print_status "warn" "1Password S3 endpoint: ${S3_ENDPOINT:-'Not set'} (expected: https://s3.hypyr.space)"
        fi

        if [[ "$S3_ACCESS_KEY" == seaweedfs-* ]]; then
            print_status "ok" "1Password has SeaweedFS access key configured"
        else
            print_status "warn" "1Password access key doesn't appear to be for SeaweedFS"
        fi
    else
        print_status "warn" "1Password CLI not signed in - cannot check configuration"
    fi
else
    print_status "warn" "1Password CLI not found - cannot check configuration"
fi

# Test S3 functionality if credentials are available
echo
echo "🪣 Testing S3 functionality..."

if command -v s3cmd >/dev/null 2>&1 && [[ -n "$S3_ACCESS_KEY" ]]; then
    S3_SECRET_KEY=$(op item get cloudflare --vault homelab --field S3_SECRET_ACCESS_KEY --reveal 2>/dev/null || echo "")

    if [[ -n "$S3_SECRET_KEY" ]]; then
        print_status "info" "Testing bucket listing with credentials..."

        if s3cmd ls --access_key="$S3_ACCESS_KEY" --secret_key="$S3_SECRET_KEY" --host=s3.hypyr.space --host-bucket=s3.hypyr.space 2>/dev/null | grep -q volsync; then
            print_status "ok" "volsync bucket is accessible and functional"

            # Show bucket contents
            echo
            echo "📂 Bucket contents:"
            s3cmd ls s3://volsync/ --access_key="$S3_ACCESS_KEY" --secret_key="$S3_SECRET_KEY" --host=s3.hypyr.space --host-bucket=s3.hypyr.space 2>/dev/null || print_status "info" "Bucket is empty or inaccessible"
        else
            print_status "warn" "Cannot access volsync bucket (may not exist yet)"
        fi
    else
        print_status "warn" "Cannot retrieve S3 secret key from 1Password"
    fi
else
    print_status "info" "s3cmd not available or credentials missing - skipping functionality test"
fi

# Check cluster connectivity (if kubectl is available)
echo
echo "🎛️  Checking Kubernetes cluster integration..."

if command -v kubectl >/dev/null 2>&1; then
    if kubectl cluster-info >/dev/null 2>&1; then
        print_status "ok" "Kubernetes cluster is accessible"

        # Check if volsync is deployed
        if kubectl get crd replicationsources.volsync.backube >/dev/null 2>&1; then
            print_status "ok" "VolSync CRDs are installed"

            # Check for any replication sources
            RS_COUNT=$(kubectl get replicationsources --all-namespaces --no-headers 2>/dev/null | wc -l)
            if [[ $RS_COUNT -gt 0 ]]; then
                print_status "ok" "Found $RS_COUNT replication source(s) configured"
                echo
                echo "📊 Replication Sources:"
                kubectl get replicationsources --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,METHOD:.spec.restic.repository,LAST SYNC:.status.lastSyncTime" 2>/dev/null || kubectl get replicationsources --all-namespaces 2>/dev/null
            else
                print_status "info" "No replication sources configured yet"
            fi
        else
            print_status "warn" "VolSync is not installed in the cluster"
        fi

        # Check external secrets
        if kubectl get externalsecrets --all-namespaces --no-headers 2>/dev/null | grep -q restic; then
            print_status "ok" "External secrets for volsync are configured"
        else
            print_status "info" "No volsync external secrets found (may not be deployed yet)"
        fi
    else
        print_status "warn" "Kubernetes cluster is not accessible"
    fi
else
    print_status "info" "kubectl not available - skipping cluster checks"
fi

echo
echo "📊 SUMMARY"
echo "=========="
print_status "info" "SeaweedFS health check complete"
echo
echo "🔗 Quick Links:"
echo "   • Web UI: https://s3-web.hypyr.space"
echo "   • S3 API: https://s3.hypyr.space"
echo "   • Monitor: kubectl get replicationsources -A"
echo
echo "🔄 To refresh external secrets:"
echo "   kubectl annotate externalsecrets --all external-secrets.io/force-sync=\$(date +%s) -A"
