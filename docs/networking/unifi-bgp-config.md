# UniFi BGP Configuration for Kubernetes LoadBalancer

This document contains the BGP configuration needed on the UniFi Dream Machine to enable Cilium LoadBalancer services.

## Background

The Kubernetes cluster uses Cilium with BGP to advertise LoadBalancer service IPs. The cluster nodes peer with the UniFi router using BGP to announce routes for the LoadBalancer IP pool.

## Network Details

- **Cluster ASN:** 64514
- **UniFi Router ASN:** 64513
- **LoadBalancer IP Pool:** 10.0.48.50-10.0.48.200
- **Node IPs:** 
  - home01: 10.0.5.215
  - home02: 10.0.5.220
  - home03: 10.0.5.100

## UniFi Configuration

Navigate to: **Network → Routing & Firewall → BGP**

### BGP Settings

- **Name:** `kubernetes-bgp`
- **Device:** Main Cloud Gateway Max
- **Override WAN Monitors:** Unchecked

### BGP Configuration File

```
router bgp 64513
 bgp router-id 10.0.5.1
 bgp listen range 10.0.5.0/24 peer-group kubernetes-nodes
 !
 neighbor kubernetes-nodes peer-group
 neighbor kubernetes-nodes remote-as 64514
 !
 address-family ipv4 unicast
  neighbor kubernetes-nodes activate
 exit-address-family
!
```

## What This Does

1. **Sets Router ASN:** Configures the UniFi router with ASN 64513
2. **Dynamic Neighbor Discovery:** Uses `bgp listen range` to automatically accept BGP connections from any IP in 10.0.5.0/24 with ASN 64514
3. **Peer Group Configuration:** All Kubernetes nodes join the `kubernetes-nodes` peer group with common settings
4. **Route Advertisement:** Allows the cluster to advertise LoadBalancer IPs to the router
5. **Traffic Routing:** Router learns how to route LoadBalancer traffic to cluster nodes

### Benefits of Dynamic Configuration
- **Automatic Node Discovery:** New nodes are automatically accepted without manual configuration
- **Simplified Management:** No need to manually add/remove individual neighbor entries
- **Scalability:** Supports cluster expansion without BGP config changes

## Verification

After applying the configuration:

1. **Check BGP Status in UniFi:** Look for established BGP sessions
2. **Verify from Cluster:**
   ```bash
   kubectl get ciliumbgpclusterconfigs -o yaml
   kubectl logs -n kube-system -l k8s-app=cilium | grep -i bgp
   ```
3. **Test LoadBalancer Connectivity:**
   ```bash
   ping 10.0.48.55  # kube-vip LoadBalancer IP
   ```

## Troubleshooting

- **BGP Not Establishing:** Check that node IPs are correct and reachable
- **Routes Not Advertised:** Verify Cilium BGP configuration matches UniFi ASNs
- **LoadBalancer Not Reachable:** Ensure IP pool is correct and services are running

## Related Files

- Cilium BGP Config: `kubernetes/apps/kube-system/cilium/config/l3.yaml`
- LoadBalancer Pool: `kubernetes/apps/kube-system/cilium/config/pool.yaml`
- L2 Policy: `kubernetes/apps/kube-system/cilium/config/l2.yaml`