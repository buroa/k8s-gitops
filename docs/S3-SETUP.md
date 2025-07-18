# SeaweedFS S3 Setup Guide for Synology NAS

This guide helps you set up [SeaweedFS](https://github.com/seaweedfs/seaweedfs) as a lightweight S3-compatible storage solution for your Kubernetes volsync backups using the Synology Container Manager UI.

## Why SeaweedFS?

- **Extremely lightweight**: Much lower resource usage than MinIO or Garage
- **Simple configuration**: No complex TOML files or permission issues
- **Single binary**: Everything in one container
- **S3-compatible**: Works with existing S3 tools
- **Synology-friendly**: Fewer Docker compatibility issues
- **Fast**: Designed for performance and simplicity

## Setup Steps

### 1. Create Data Directory

Create the directory structure:

```bash
mkdir -p /volume1/docker/seaweedfs/data
sudo chown -R 1000:1000 /volume1/docker/seaweedfs/
```

### 2. Deploy SeaweedFS via Container Manager

**Manual Container Creation:**

1. **Container Manager** → **Container** → **Create**
2. **General Settings**:
   - **Container Name**: `seaweedfs`
   - **Image**: `chrislusf/seaweedfs:latest`
   - **Auto-restart**: ✅ Enabled
3. **Port Settings** → **Add**:
   - Local Port: `8333`, Container Port: `8333` (S3 API)
   - Local Port: `9333`, Container Port: `9333` (Master/Web UI)
4. **Volume Settings** → **Add Folder**:
   - **Folder**: `/volume1/docker/seaweedfs/data` → **Mount path**: `/data`
5. **Environment** → **Add**:
   - **Variable**: `WEED_MASTER_VOLUME_SIZE_LIMIT_MB`, **Value**: `1000`
6. **Advanced Settings** → **Execute Command**:
   - **Command**: `server`
   - **Arguments**: `-s3 -dir=/data -s3.port=8333 -master.port=9333`
7. **Resource Limits** (for slower Synology models):
   - **CPU Priority**: `Low` or `Medium`
   - **Memory Limit**: Set to `256MB` or `512MB`
8. **Apply** → **Next** → **Done**

**Docker Compose Alternative:**

```bash
mkdir -p /volume1/docker/seaweedfs
cat > /volume1/docker/seaweedfs/docker-compose.yml << 'EOF'
version: '3.8'

services:
  seaweedfs:
    image: chrislusf/seaweedfs:latest
    restart: unless-stopped
    ports:
      - "8333:8333"  # S3 API
      - "9333:9333"  # Master/Web UI
    volumes:
      - ./data:/data
    command: ["server", "-s3", "-dir=/data", "-s3.port=8333", "-master.port=9333"]
    environment:
      - WEED_MASTER_VOLUME_SIZE_LIMIT_MB=1000

networks:
  default:
    driver: bridge
EOF
```

### 3. Test SeaweedFS

Once the container is running:

**Check Web UI:**
- Open `http://razzia.hypyr.space:9333` in your browser
- You should see the SeaweedFS admin interface

**Test S3 API:**
```bash
# Test S3 connectivity
curl -I http://razzia.hypyr.space:8333

# Should return HTTP 400 or similar (means SeaweedFS is responding)
```

### 4. Create Proper S3 Credentials

Generate real credentials for 1Password (instead of using "any"):

```bash
# Generate secure S3 credentials
S3_ACCESS_KEY="seaweedfs-$(openssl rand -hex 8)"
S3_SECRET_KEY=$(openssl rand -base64 32)

echo "Generated S3 Credentials:"
echo "Access Key: $S3_ACCESS_KEY"
echo "Secret Key: $S3_SECRET_KEY"
echo
echo "Save these to 1Password!"
```

### 5. Test S3 Access with Your HTTPS Endpoints

Test with your actual production endpoints:

```bash
# Test S3 API via your HTTPS endpoint
curl -I https://s3.hypyr.space

# Create the volsync bucket (using your proper credentials)
s3cmd mb s3://volsync
  --access_key="$S3_ACCESS_KEY"
  --secret_key="$S3_SECRET_KEY"
  --host=s3.hypyr.space
  --host-bucket=s3.hypyr.space

# Test listing buckets
s3cmd ls
  --access_key="$S3_ACCESS_KEY"
  --secret_key="$S3_SECRET_KEY"
  --host=s3.hypyr.space
  --host-bucket=s3.hypyr.space

# Test file upload
echo "test content" | s3cmd put - s3://volsync/test.txt
  --access_key="$S3_ACCESS_KEY"
  --secret_key="$S3_SECRET_KEY"
  --host=s3.hypyr.space
  --host-bucket=s3.hypyr.space
```

**Note**: SeaweedFS by default allows any access key/secret key, but using proper credentials is more secure and matches your production setup.

### 6. Update 1Password Integration

Update your 1Password entry with the generated credentials:

```bash
# Update the cloudflare entry with SeaweedFS S3 credentials
op item edit cloudflare --vault homelab
  "S3_ACCESS_KEY_ID[text]=$S3_ACCESS_KEY"
  "S3_SECRET_ACCESS_KEY[concealed]=$S3_SECRET_KEY"
  "S3_ENDPOINT[text]=https://s3.hypyr.space"
  "S3_REGION[text]=us-east-1"

echo "✅ 1Password updated with SeaweedFS credentials"
echo "🌐 S3 API: https://s3.hypyr.space"
echo "🖥️  Web UI: https://s3-web.hypyr.space"
```

### 5. Update 1Password Integration

Update your 1Password entry for volsync:

```bash
```bash
# Update the cloudflare entry with SeaweedFS S3 credentials
op item edit cloudflare --vault homelab \
  "S3_ACCESS_KEY_ID[text]=seaweedfs-access" \
  "S3_SECRET_ACCESS_KEY[concealed]=seaweedfs-secret" \
  "S3_ENDPOINT[text]=http://razzia.hypyr.space:8333" \
  "S3_REGION[text]=us-east-1"
```

## DNS and Network Configuration

To use the clean `https://s3.hypyr.space` endpoint (which matches your existing 1Password setup), we'll set up DNS and reverse proxy.

### 1. UniFi Router DNS Setup

1. **Open UniFi Network Controller**
2. **Settings** → **Networks** → **Default**
3. **Advanced** → **DHCP Name Server** → **Manual**
4. **DNS Server**: Add your router IP (usually 10.0.5.1)
5. **Settings** → **System** → **Advanced Features**
6. **Enable Advanced Features** → **DNS**
7. **Create DNS Records**:
   **Essential (for volsync):**
   - **Record Type**: CNAME
   - **Name**: `s3.hypyr.space`
   - **Value**: `razzia.hypyr.space`
   - **TTL**: 86400

   **Optional (only if you want admin access):**
   - **Name**: `s3-admin.hypyr.space` → `razzia.hypyr.space`

**Benefits of using CNAMEs:**
- ✅ If your NAS IP changes, only update razzia.hypyr.space
- ✅ All service endpoints automatically follow the change
- ✅ Easier to manage and more flexible

### 2. Synology Reverse Proxy Setup (DSM 7.2+)

**Setup for SeaweedFS:**

Create **one reverse proxy rule** for your S3 API:
- **Description**: `SeaweedFS S3 API`
- **Source**: `https://s3.hypyr.space:443`
- **Destination**: `http://localhost:8333`

**Optional: Add admin access if needed:**
- **Description**: `SeaweedFS Admin UI`
- **Source**: `https://s3-admin.hypyr.space:443`
- **Destination**: `http://localhost:9333`

**How to create:**
1. **DSM** → **Control Panel** → **Login Portal** → **Advanced** tab
2. **Reverse Proxy** section → **Create**
3. **Fill in the details** for the rule above
4. **Enable HSTS** ✅ (recommended)
5. **Apply**

**Each hostname requires its own reverse proxy rule** - Synology doesn't support multi-hostname routing in a single rule.

**Note**: DSM 7.2+ has reverse proxy settings scattered across multiple locations (typical Synology):
- **Control Panel** → **Login Portal** → **Advanced** tab → **Reverse Proxy** (primary location)
- **Control Panel** → **Application Portal** → **Reverse Proxy** (legacy/alternative location)
- **Package Center** → **Web Station** → **General Settings** → **Reverse Proxy** (if Web Station installed)

Try them in order until you find the one that works in your DSM version. The interface locations are inconsistent across DSM updates.

## 🎯 **READY FOR KUBERNETES!**

Your SeaweedFS S3 is now fully configured and ready for volsync backups!

### ✅ **What's Set Up:**

1. **✅ SeaweedFS Container**: Running on Synology with persistent storage
2. **✅ HTTPS Endpoints**:
   - S3 API: `https://s3.hypyr.space`
   - Web UI: `https://s3-web.hypyr.space`
3. **✅ 1Password Integration**: Dedicated `seaweedfs` entry with all credentials
4. **✅ VolSync Templates**: Ready-to-use Kubernetes components
5. **✅ Management Scripts**: Complete toolset for monitoring and maintenance

### 📋 **Cluster Integration:**

Your cluster can now use the SeaweedFS volsync component:

```yaml
# In your app's kustomization.yaml
components:
  - ../../../components/volsync/seaweedfs
```

### 🚀 **Quick Start Commands:**

```bash
# Run the integration (if not done already)
./scripts/setup-seaweedfs-k8s-integration.sh

# Check status
./scripts/check-seaweedfs-status.sh

# Setup monitoring
./scripts/setup-seaweedfs-monitoring.sh

# When cluster is ready, refresh external secrets
kubectl annotate externalsecrets --all external-secrets.io/force-sync=$(date +%s) -A
```

### 🌐 **Admin Access:**

- **Web UI**: https://s3-web.hypyr.space
- **Direct S3**: Port 8333 on `razzia.hypyr.space`
- **Direct Admin**: Port 9333 on `razzia.hypyr.space`

### 📊 **Monitoring:**

Monitor your backups via:
- **VolSync**: `kubectl get replicationsources -A`
- **Jobs**: `kubectl get jobs -A | grep restic`
- **Storage**: SeaweedFS Web UI
- **External Secrets**: `kubectl get externalsecrets -A`

---

## Legacy Information

The sections below contain the full setup guide and troubleshooting information for reference.

You can have SeaweedFS running in about 5 minutes! Let's test it immediately:

**1. Open Container Manager**
- **DSM** → **Package Center** → **Container Manager** → **Open**

**2. Create Container (Manual Method)**
- **Container** → **Create**
- **General Settings**:
  - **Container Name**: `seaweedfs-test`
  - **Image**: `chrislusf/seaweedfs:latest`
  - **Auto-restart**: ✅ Enabled
- **Port Settings** → **Auto** (let it pick random ports)
- **Advanced Settings** → **Execute Command**:
  - **Command**: `server`
  - **Arguments**: `-s3 -dir=/tmp/data -s3.port=8333 -master.port=9333`
- **Apply** → **Next** → **Done**

**3. Check if it works**
- After creation, check the **Port** column in Container Manager
- Look for ports like `32768:8333` and `32769:9333`
- Open `http://razzia.hypyr.space:32769` (the 9333 port) in your browser
- You should see the SeaweedFS admin UI!

**4. Test S3 API**
```bash
# From your computer, test the S3 API (use the port mapped to 8333)
curl -I http://razzia.hypyr.space:32768
```

If this works, we can move to the production setup with proper port mapping and persistent storage!

## Production Setup Steps

Since Synology doesn't support Cloudflare DNS auth natively, use `acme.sh` for proper Let's Encrypt certificates:

**Setup acme.sh (one-time)**
```bash
ssh cpritchett@razzia.hypyr.space
curl https://get.acme.sh | sh -s email=chad@chadpritchett.com
source ~/.bashrc
```

**Configure Cloudflare DNS API**
```bash
# Set your Cloudflare credentials
export CF_Token="your-cloudflare-api-token"
export CF_Account_ID="your-cloudflare-account-id"

# Or use Global API Key method:
# export CF_Key="your-global-api-key"
# export CF_Email="your-cloudflare-email"
```

**Issue certificates for all Garage domains**
```bash
~/.acme.sh/acme.sh --issue --dns dns_cf \
  -d s3.hypyr.space \
  -d s3-admin.hypyr.space \
  -d s3-web.hypyr.space
```

**Install certificates to Synology**
```bash
~/.acme.sh/acme.sh --deploy -d s3.hypyr.space --deploy-hook synology_dsm \
  --insecure \
  --SYNO_Username=admin \
  --SYNO_Password="your-dsm-password" \
  --SYNO_Certificate="s3.hypyr.space" \
  --SYNO_Create=1
```

**Set up automatic renewal**
The certificates will auto-renew, but you can also set up a Synology scheduled task:
1. **Control Panel** → **Task Scheduler** → **Create** → **Scheduled Task** → **User-defined script**
2. **General**: Name it "Renew SSL Certificates"
3. **Schedule**: Monthly on the 1st at 3:00 AM
4. **Task Settings** → **Run command**:
```bash
/var/services/homes/cpritchett/.acme.sh/acme.sh --cron --home /var/services/homes/cpritchett/.acme.sh
```

**Benefits of this approach:**
- ✅ Proper trusted certificates (no browser warnings)
- ✅ Automatic renewal
- ✅ Works with Kubernetes without trust store modifications
- ✅ Professional setup

### 4. Test the Setup

```bash
# Test DNS resolution
nslookup s3.hypyr.space

# Test HTTPS connectivity
curl -I https://s3.hypyr.space

# Should return HTTP 400 (which means Garage is responding)
```your Kubernetes volsync backups using the Synology Container Manager UI.

## Why Garage?

- **Lightweight**: Much lower resource usage than MinIO
- **Distributed**: Built for multi-node deployments
- **Self-healing**: Handles failures gracefully
- **S3-compatible**: Works with existing S3 tools
- **Rust-based**: Memory safe and efficient
- **Latest version**: v2.0.0 with improved admin API and performance

**Breaking changes in v2.0.0**:
- `replication_mode` has been replaced with `replication_factor` and `consistency_mode`
- Admin API has been completely reworked (v1 endpoints deprecated)
- Performance and reliability improvements

## Setup Steps

### 1. Set Up DNS and Reverse Proxy First

**Important**: Set this up before deploying Garage so the SSL certificate can be obtained.

Follow the [DNS and Network Configuration](#dns-and-network-configuration) section below to:
1. Configure DNS in UniFi Router
2. Set up reverse proxy in Synology DSM
3. Obtain Let's Encrypt SSL certificate
4. Test that `https://s3.hypyr.space` is accessible

### 2. Create Configuration File (One-time SSH)

**Quick setup via SSH** (just to create the config file):

```bash
ssh cpritchett@razzia.hypyr.space
mkdir -p /volume1/docker/garage/{data,meta}

# Fix permissions for Docker container access
sudo chown -R 1026:100 /volume1/docker/garage/
chmod -R 755 /volume1/docker/garage/

cat > /volume1/docker/garage/garage.toml << 'EOF'
metadata_dir = "/garage/meta"
data_dir = "/garage/data"

db_engine = "sqlite"
replication_factor = 1
consistency_mode = "consistent"
compression_type = "zstd"

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "razzia.hypyr.space:3901"
rpc_secret = "1799bccfd7411eddcf9ebd316bc1f5287ad12a68094e30de6d91698936ed6be5"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"

[s3_web]
bind_addr = "[::]:3902"
index = "index.html"

[k2v_api]
api_bind_addr = "[::]:3904"

[admin]
api_bind_addr = "[::]:3903"
metrics_token = "7a8f3c2e9b1d4a6e5f8c9e2b4d7a1f3c6e9b2d5a8f1c4e7b0d3a6f9c2e5b8d1a4"
admin_token = "9e4b7d1a5c8f2e6b9d2a5f8c1e4b7d0a3f6c9e2b5d8a1f4c7e0b3d6a9f2c5e8b1"
EOF
exit
```

### 3. Deploy Garage via Container Manager (Docker Compose)

**Create Docker Compose file via SSH:**

```bash
ssh cpritchett@razzia.hypyr.space
mkdir -p /volume1/docker/garage
cat > /volume1/docker/garage/docker-compose.yml << 'EOF'
version: '3.8'

services:
  garage:
    image: dxflrs/garage:v2.0.0
    restart: unless-stopped
    user: "1026:100"  # Match Synology user cpritchett:users
    ports:
      - "3900:3900"  # S3 API
      - "3901:3901"  # RPC
      - "3902:3902"  # Web Interface
      - "3903:3903"  # Admin API
    volumes:
      - ./garage.toml:/etc/garage.toml:ro
      - ./meta:/garage/meta
      - ./data:/garage/data
    environment:
      - RUST_LOG=garage=info

networks:
  default:
    driver: bridge
EOF
exit
```

**Deploy via Container Manager:**

1. **Open DSM** → **Container Manager**
2. **Project** tab → **Create**
3. **Set up project**:
   - **Project name**: `garage`
   - **Path**: `/volume1/docker/garage`
   - **Source**: Select **Create docker-compose.yml**
4. **Upload the compose file** or **paste the content** from above
5. **Build and start** the project

**Alternative: Manual upload method**
1. Upload the `docker-compose.yml` file to `/volume1/docker/garage/` via File Station
2. **Container Manager** → **Project** → **Create**
3. **Set up project** → **Use existing docker-compose.yml**
4. **Select path**: `/volume1/docker/garage`
5. **Next** → **Done**

**If you get "failed to create shim task" errors:**

**Quick Fix #1: Restart Container Manager**
1. **DSM** → **Package Center** → **Installed**
2. Find **Container Manager** → **Stop**
3. Wait 30 seconds → **Start**
4. Try creating the container again

**Quick Fix #2: Clean Docker State**
```bash
# Stop all containers and clean Docker
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
sudo docker system prune -af
# Restart Docker on Synology (not systemctl)
sudo synopkg restart Docker
```

**Fallback: Manual Container Creation (skip Docker Compose entirely)**
If the above doesn't work, create the container manually:

1. **Container Manager** → **Container** → **Create**
2. **General Settings**:
   - **Container Name**: `garage`
   - **Image**: `dxflrs/garage:v2.0.0`
   - **Auto-restart**: ✅ Enabled
3. **Advanced Settings** → **Execution Environment**:
   - **User ID**: `1026` (matches your Synology user)
4. **Port Settings** → **Add**:
   - Local Port: `3900`, Container Port: `3900` (S3 API)
   - Local Port: `3901`, Container Port: `3901` (RPC)
   - Local Port: `3902`, Container Port: `3902` (Web Interface)
   - Local Port: `3903`, Container Port: `3903` (Admin API)
5. **Volume Settings** → **Add Folder**:
   - **File**: `/volume1/docker/garage/garage.toml` → **Mount path**: `/etc/garage.toml` (Read-only ✅)
   - **Folder**: `/volume1/docker/garage/meta` → **Mount path**: `/garage/meta`
   - **Folder**: `/volume1/docker/garage/data` → **Mount path**: `/garage/data`
6. **Environment** → **Add**:
   - **Variable**: `RUST_LOG`, **Value**: `garage=info`
7. **Resource Limits** (for slower Synology models):
   - **CPU Priority**: `Low` or `Medium` (saves CPU for other services)
   - **Memory Limit**: Set to `512MB` or `1GB` depending on available RAM
8. **Apply** → **Next** → **Done**

**Critical: User/Group Permission Fix**
The most common cause of Garage container failures on Synology is permission mismatches. Your Synology user `cpritchett` has UID 1026, but Docker containers often run as UID 1000. This causes mount permission errors.

**Fix this by:**
1. Setting the container user to match your Synology user (steps above)
2. OR: Change the directory ownership to match the container's default user:
   ```bash
   ssh cpritchett@razzia.hypyr.space
   sudo chown -R 1000:1000 /volume1/docker/garage/
   ```

**For resource-constrained Synology models**:
- Use the CPU priority and memory limit sliders to prevent Garage from overwhelming your NAS
- SQLite database engine (already configured) is lighter on resources than LMDB
- Monitor container resource usage in Container Manager's performance tab

This bypasses Docker Compose entirely and often resolves shim task issues.

### 4. Configure Garage Cluster (via SSH)

Once the container is running:

```bash
# SSH to your NAS
ssh cpritchett@razzia.hypyr.space

# Get the node ID
docker exec garage /garage node id

# Configure the cluster (replace <NODE_ID> with the actual ID)
docker exec garage /garage layout assign <NODE_ID> --zone dc1 --capacity 100G --tag nas
docker exec garage /garage layout apply --version 1

# Create bucket and access key
docker exec garage /garage bucket create volsync
docker exec garage /garage key create volsync-key
docker exec garage /garage bucket allow volsync --read --write --key volsync-key

# Get the credentials (save these!)
docker exec garage /garage key info volsync-key
```

**Note for v2.0.0**: The CLI commands remain compatible, but the admin API has been completely reworked. If you need to use the admin API directly, refer to the new v2 API endpoints.

### 5. Update 1Password and Kubernetes Integration

Once you have your S3 credentials from step 3, use this script to integrate with your cluster:

```bash
./scripts/setup-garage-k8s-integration.sh
```

This script will:
- Prompt you for the S3 Access Key and Secret Key from Garage
- Update your `cloudflare` 1Password entry with the new S3 credentials
- Preserve your existing Cloudflare API token
- Test the integration

## Monitoring

Check Garage status:

```bash
# Container logs (via DSM or SSH)
docker logs garage

# Garage cluster status
docker exec garage /garage status

# List buckets and keys
docker exec garage /garage bucket list
docker exec garage /garage key list
```

## Testing Your Setup

Test S3 connectivity using the HTTPS endpoint:

```bash
# Install s3cmd for testing
pip install s3cmd

# Test bucket access via reverse proxy
s3cmd ls s3://volsync \
  --access_key=<YOUR_ACCESS_KEY> \
  --secret_key=<YOUR_SECRET_KEY> \
  --host=s3.hypyr.space \
  --host-bucket=s3.hypyr.space

# If you need to troubleshoot, test direct access:
s3cmd ls s3://volsync \
  --access_key=<YOUR_ACCESS_KEY> \
  --secret_key=<YOUR_SECRET_KEY> \
  --host=razzia.hypyr.space:3900 \
  --host-bucket=razzia.hypyr.space:3900 \
  --no-ssl
```

## DNS and Network Configuration

**Important**: Your current 1Password setup expects `https://s3.hypyr.space` as the S3 endpoint. You have two options:

### Option A: Use Direct IP Access (Simpler)
Update your 1Password entry to use: `http://razzia.hypyr.space:3900`

### Option B: Set up DNS/Reverse Proxy (Cleaner)
1. **DNS**: Point `s3.hypyr.space` to your NAS IP (10.0.5.x)
2. **Reverse Proxy**: Configure nginx/traefik to proxy HTTPS to port 3900
3. **SSL Certificate**: Use Let's Encrypt for HTTPS

For now, the integration script will use `https://s3.hypyr.space` to match your existing setup.

## Benefits for Your Setup

- **UI Management**: Easy setup and monitoring via Synology DSM
- **Local backups**: No internet dependency for volsync operations
- **Cost savings**: No cloud storage fees
- **Performance**: Faster backup/restore on local network
- **Privacy**: All data stays on your infrastructure
- **Reliability**: Garage handles failures gracefully

## Troubleshooting

**DSM 7.2+ Specific Issues:**
- **Reverse Proxy not found**: Try **Package Center** → Install **Web Station** first
- **Let's Encrypt fails**: Internal domains always fail LE validation; use self-signed certificates
- **Certificate not applying**: Go to **Configure** → **Settings** to assign certificates to services

**SSL Certificate Issues:**
- **Certificate renewal fails**: Check Cloudflare API credentials in acme.sh
- **Certificate not applying to DSM**: Re-run the deploy command with correct SYNO credentials
- **"Certificate expired" errors**: Ensure the scheduled renewal task is working
- **Domain validation fails**: Verify DNS records are properly configured in Cloudflare

**Mount Permission Problems (Very Common on Synology):**

**CONFIRMED: If Garage starts without volumes but fails with volumes, it's a mount permission issue.**

- **"Permission denied" errors**: Container user doesn't match file ownership
- **Container fails to start**: Check ownership of `/volume1/docker/garage/` directory
- **Database/metadata errors**: SQLite can't write to `/garage/meta` due to permissions
- **"failed to create shim task"** when volumes are added: Mount path permissions

**Fix mount permissions (try in order):**
```bash
# Option 1: Change ownership to match container's default user (UID 1000)
sudo chown -R 1000:1000 /volume1/docker/garage/

# Option 2: Make directories world-writable (quick fix)
sudo chmod -R 777 /volume1/docker/garage/

# Option 3: Change ownership to match your Synology user
sudo chown -R 1026:100 /volume1/docker/garage/
# PLUS set container user in Container Manager: User ID: 1026, Group ID: 100
```

**Check what user the container expects:**
```bash
# See what user Garage runs as by default
sudo docker run --rm dxflrs/garage:v2.0.0 id
```

**Verify permissions:**
```bash
# Check directory ownership
ls -la /volume1/docker/garage/

# Should show either:
# - drwxr-xr-x 1000 1000 (if using Option 1)
# - drwxr-xr-x 1026 100  (if using Option 2)
# - drwxrwxrwx any  any   (if using Option 3)
```

**Docker "Failed to Create Shim Task" Errors (VERY COMMON):**

**This is the #1 issue with Synology Docker. Try these in order:**

**First: Test with Hello World container to isolate the issue:**
```bash
# Test if Docker works at all
sudo docker run --rm hello-world

# If that fails, try via Container Manager UI:
# Container Manager → Container → Create
# Image: hello-world
# No ports, volumes, or special settings needed
```

If hello-world works but Garage doesn't, it's a Garage-specific issue (likely resource/configuration).
If hello-world fails too, it's a general Docker problem.

1. **Restart Container Manager** (fixes 80% of cases):
   - **Package Center** → **Container Manager** → **Stop** → **Start**

2. **Clean Docker state**:
   ```bash
   sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
   sudo docker system prune -af
   # Restart Docker on Synology (not systemctl)
   sudo synopkg restart Docker
   ```

3. **Reset Container Manager completely**:
   ```bash
   sudo synopkg stop ContainerManager
   sudo rm -rf /volume1/@docker/containers/*
   sudo synopkg start ContainerManager
   ```

4. **Use manual container creation** instead of Docker Compose (often works when Compose fails)

5. **Check disk space**:
   ```bash
   df -h /volume1/@docker
   # If >90% full, clean up old images/containers
   ```

**Nuclear option: Manual Docker commands** (bypass Container Manager entirely):
```bash
sudo docker run -d --name garage \
  --restart unless-stopped \
  -p 3900:3900 -p 3901:3901 -p 3902:3902 -p 3903:3903 \
  -v /volume1/docker/garage/garage.toml:/etc/garage.toml:ro \
  -v /volume1/docker/garage/meta:/garage/meta \
  -v /volume1/docker/garage/data:/garage/data \
  -e RUST_LOG=garage=info \
  dxflrs/garage:v2.0.0
```

**Other Docker fixes:**

**Synology-Specific Docker Issues:**
- **DSM 7.x Docker breakage**: Container Manager sometimes corrupts after updates
- **Permission problems**: Ensure user is in `docker` group: `sudo usermod -aG docker $USER`
- **Storage driver issues**: Synology uses BTRFS which can conflict with overlay2
- **Memory limits**: DSM can kill containers unexpectedly under memory pressure
- **Network conflicts**: Multiple Docker networks can cause routing issues
- **Volume mount failures**: Path `/volume1/docker/` must exist and be writable

**Nuclear Options (when all else fails):**
- **Reinstall Container Manager**: Package Center → Remove → Reinstall
- **Manual Docker commands**: Bypass Container Manager entirely:
  ```bash
  sudo docker run -d --name garage \
    --restart unless-stopped \
    -p 3900:3900 -p 3901:3901 -p 3902:3902 -p 3903:3903 \
    -v /volume1/docker/garage/garage.toml:/etc/garage.toml:ro \
    -v /volume1/docker/garage/meta:/garage/meta \
    -v /volume1/docker/garage/data:/garage/data \
    -e RUST_LOG=garage=info \
    dxflrs/garage:v2.0.0
  ```
- **Use Podman instead**: If Docker is completely broken, install Podman as replacement
- **VM deployment**: Run Garage in a Synology VM with proper Linux instead

**General Issues:**
- **Container not starting**: Check logs in Container Manager
- **Port conflicts**: Ensure ports 3900-3903 are available
- **Permission issues**: Verify volume mounts are accessible
- **Network access**: Test connectivity to port 3900 from your cluster
- **DNS not resolving**: Check UniFi Controller → **System** → **Advanced Features** is enabled

**Alternative: Skip HTTPS for Internal Use**
If SSL proves problematic, consider using `http://s3.hypyr.space` instead:
1. Set up reverse proxy without SSL (HTTP:80 → HTTP:3900)
2. Update integration script endpoint to use HTTP
3. Simpler setup, adequate security for internal network
