# VolSync with SeaweedFS S3

This component provides templates for backing up persistent volumes to SeaweedFS S3 storage using VolSync.

## Configuration

The external secret references the `seaweedfs` 1Password entry which contains:

- `S3_ACCESS_KEY_ID`: SeaweedFS S3 access key
- `S3_SECRET_ACCESS_KEY`: SeaweedFS S3 secret key
- `S3_ENDPOINT`: https://s3.hypyr.space
- `S3_REGION`: us-east-1
- `REPOSITORY_TEMPLATE`: s3:https://s3.hypyr.space/volsync
- `RESTIC_PASSWORD`: Encryption password for restic backups

## Usage

To use this template in an application, include it as a component:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
metadata:
  name: my-app
  namespace: my-app
components:
  - ../../../components/volsync/seaweedfs
resources:
  - ...
patches:
  - target:
      kind: ExternalSecret
      name: "*-restic"
    patch: |
      - op: replace
        path: /metadata/name
        value: my-app-restic
```

## Environment Variables

Applications can override these values:

- `APP`: Application name (used for bucket path)
- `VOLSYNC_SCHEDULE`: Backup schedule (default: "0 0 * * *" - daily at midnight)
- `VOLSYNC_SNAPSHOTCLASS`: Volume snapshot class (default: "csi-ceph-blockpool")
- `VOLSYNC_STORAGECLASS`: Storage class (default: "ceph-block")
- `VOLSYNC_UID`: User ID for mover pod (default: "568")
- `VOLSYNC_GID`: Group ID for mover pod (default: "568")

## Monitoring

Monitor backup status:

```bash
# Check replication sources
kubectl get replicationsources -A

# Check backup jobs
kubectl get jobs -A | grep restic

# Check external secrets
kubectl get externalsecrets -A | grep restic
```

## Management

Use the provided scripts for setup and monitoring:

```bash
# Setup SeaweedFS integration
./scripts/setup-seaweedfs-k8s-integration.sh

# Check SeaweedFS status
./scripts/check-seaweedfs-status.sh

# Setup monitoring
./scripts/setup-seaweedfs-monitoring.sh
```
