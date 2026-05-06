When a Service doesn't route traffic correctly despite having valid Endpoints, **kube-proxy** is usually the culprit. As the "network traffic controller" on every node, it is responsible for translating Service ClusterIPs into actual Pod IPs using system rules (iptables or IPVS).

---

## 1. Initial Health Check
Kube-proxy runs as a **DaemonSet**. If it isn't running on the specific node where your client Pod resides, that Pod will never be able to reach a Service.

```bash
# 1. Check if all kube-proxy pods are running
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# 2. Check for restarts (indicates crashing or OOMKill)
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

---

## 2. Inspecting the Logs
If the pods are "Running" but traffic is still failing, check the logs for synchronization errors. Kube-proxy must constantly "watch" the API server for changes.

```bash
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=50
```
**Look for these red flags:**
*   `Failed to execute iptables-restore`: Indicates a conflict with the node's firewall or kernel version.
*   `Attempting to reconnect to apiserver`: Network issues between the worker node and the control plane.
*   `error updating boundary node`: Often related to CNI (network plugin) incompatibilities.

---

## 3. Investigating the Data Plane (iptables)
In most clusters, kube-proxy operates in **iptables mode**. You can verify if the rules for your Service actually exist on the worker node.



**Step 1: Get the ClusterIP of your Service**
```bash
kubectl get svc my-service
```

**Step 2: SSH into the Worker Node and search the NAT table**
```bash
# Run this on the node itself
iptables -t nat -L KUBE-SERVICES | grep <cluster-ip>
```
*   **Success:** You see a rule redirecting to a `KUBE-SVC-XXX` chain.
*   **Failure:** If no rules appear, kube-proxy has failed to sync with the API server.

---

## 4. Common Failure Scenarios

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Congested Conntrack Table** | Node is handling too many simultaneous connections. | Increase `net.netfilter.nf_conntrack_max` in sysctl or scale nodes. |
| **Duplicate Rules** | Leftover rules from a previous CNI or manual edit. | Flush iptables (`iptables -F`) and restart kube-proxy pod. |
| **Mode Mismatch** | Using IPVS mode without the required kernel modules loaded. | Ensure `ip_vs` modules are loaded on the host OS. |
| **API Server Latency** | Kube-proxy is timing out while fetching Endpoint updates. | Check control plane health and node-to-master latency. |

---

## 5. Advanced: IPVS vs. iptables
If your cluster has thousands of Services, iptables becomes slow because it performs a linear search through rules.



**To check which mode your kube-proxy is using:**
```bash
kubectl describe configmap -n kube-system kube-proxy | grep mode
```
*   **If using IPVS:** Use `ipvsadm -Ln` on the node to see the load-balancing virtual server entries. It is much easier to read than iptables.

---

## 6. Summary Troubleshooting Checklist
1.  **Is the Pod running?** (`kubectl get pods -n kube-system`)
2.  **Are there logs about "Sync failures"?** (`kubectl logs`)
3.  **Does the node have disk space?** (Full disks prevent log writing and container execution).
4.  **Are the kernel modules loaded?** (Specifically for IPVS).
5.  **Is there a firewall (firewalld/ufw) blocking the proxy?** (Turn off host firewalls to test).
