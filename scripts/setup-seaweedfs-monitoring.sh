#!/bin/bash

echo "🌊 SEAWEEDFS MONITORING SETUP"
echo "============================="
echo "Setting up monitoring and alerting for SeaweedFS"
echo

# Check if we can reach the endpoints
echo "🔍 Checking SeaweedFS endpoints..."

if curl -sI https://s3.hypyr.space >/dev/null 2>&1; then
    echo "✅ S3 API endpoint is accessible"
else
    echo "❌ S3 API endpoint is not accessible"
    exit 1
fi

if curl -sI https://s3-web.hypyr.space >/dev/null 2>&1; then
    echo "✅ Web UI endpoint is accessible"
else
    echo "❌ Web UI endpoint is not accessible"
    exit 1
fi

echo
echo "📊 SeaweedFS Monitoring Options:"
echo "==============================="
echo

echo "1. 📈 GRAFANA DASHBOARD SETUP"
echo "   - Add SeaweedFS monitoring to your existing Grafana"
echo "   - Monitor storage usage, request rates, and performance"
echo

echo "2. 🚨 PROMETHEUS ALERTS"
echo "   - Set up alerts for SeaweedFS availability"
echo "   - Monitor backup job success/failure rates"
echo

echo "3. 📱 NOTIFICATION SETUP"
echo "   - Configure Discord/Slack notifications"
echo "   - Alert on backup failures or storage issues"
echo

echo "4. 🔍 LOG MONITORING"
echo "   - Monitor SeaweedFS container logs"
echo "   - Track S3 API request patterns"
echo

echo "📋 Current Monitoring Status:"
echo "============================"

# Check if Prometheus is available in cluster
if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
    if kubectl get prometheus -n observability >/dev/null 2>&1; then
        echo "✅ Prometheus is available in the cluster"

        # Check for Grafana
        if kubectl get deployment grafana -n observability >/dev/null 2>&1; then
            echo "✅ Grafana is available in the cluster"
        else
            echo "⚠️  Grafana not found in observability namespace"
        fi

        # Check for existing volsync monitoring
        if kubectl get prometheusrule volsync -n volsync-system >/dev/null 2>&1; then
            echo "✅ VolSync monitoring rules are configured"
        else
            echo "⚠️  VolSync monitoring rules not found"
        fi
    else
        echo "⚠️  Prometheus not found in observability namespace"
    fi
else
    echo "⚠️  Kubernetes cluster not accessible"
fi

echo
echo "🔧 MONITORING RECOMMENDATIONS:"
echo "=============================="

echo
echo "1. 📊 ADD SEAWEEDFS TO GRAFANA:"
echo "   • Open Grafana: kubectl port-forward -n observability svc/grafana 3000:80"
echo "   • Import SeaweedFS dashboard (if available)"
echo "   • Create custom dashboard for storage metrics"
echo

echo "2. 🚨 BACKUP MONITORING ALERTS:"
echo "   • Monitor volsync replication source status"
echo "   • Alert on failed backup jobs"
echo "   • Track backup size and frequency"
echo

echo "3. 📈 KEY METRICS TO MONITOR:"
echo "   • S3 API response times"
echo "   • Storage usage growth"
echo "   • Backup success/failure rates"
echo "   • Network I/O to SeaweedFS"
echo

echo "4. 🔍 USEFUL QUERIES:"
echo

cat << 'EOF'
   • Backup Success Rate:
     (rate(volsync_replication_source_success_total[5m]) / rate(volsync_replication_source_total[5m])) * 100

   • Storage Usage Trend:
     increase(container_fs_usage_bytes{container_label_name="seaweedfs"}[1h])

   • S3 API Availability:
     up{job="seaweedfs-metrics"}

   • Backup Job Duration:
     histogram_quantile(0.95, rate(volsync_replication_duration_seconds_bucket[5m]))
EOF

echo
echo "🎯 QUICK MONITORING SETUP:"
echo "=========================="

cat << 'EOF'
1. Monitor via Web UI:
   • Visit: https://s3-web.hypyr.space
   • Check volume usage and file counts
   • Monitor active connections

2. Monitor via kubectl:
   • kubectl get replicationsources -A
   • kubectl get jobs -A | grep restic
   • kubectl logs -n volsync-system deployment/volsync

3. Monitor via s3cmd:
   • s3cmd du s3://volsync --access_key=X --secret_key=Y --host=s3.hypyr.space
   • Check backup sizes and growth

4. System monitoring:
   • ssh cpritchett@razzia.hypyr.space "docker stats seaweedfs"
   • Monitor NAS storage usage
   • Check network bandwidth usage
EOF

echo
echo "🚨 ALERT RECOMMENDATIONS:"
echo "========================="

cat << 'EOF'
Critical Alerts:
• SeaweedFS container down
• S3 API endpoint unreachable
• Backup jobs failing consistently
• Storage usage > 90%

Warning Alerts:
• Backup duration increasing
• Storage growth rate high
• S3 API response time degraded
• Container resource usage high
EOF

echo
echo "📱 NOTIFICATION SETUP:"
echo "====================="

echo "To enable notifications, configure your existing alertmanager with:"
echo
echo "1. Discord webhook for backup failures"
echo "2. Email alerts for storage warnings"
echo "3. Slack notifications for critical issues"
echo

echo "✨ Monitoring setup information provided!"
echo
echo "🔗 Useful Links:"
echo "   • SeaweedFS Web UI: https://s3-web.hypyr.space"
echo "   • Check backup status: ./scripts/check-seaweedfs-status.sh"
echo "   • Grafana (when port-forwarded): http://localhost:3000"
echo
echo "💡 TIP: Bookmark the SeaweedFS Web UI for quick storage monitoring!"
