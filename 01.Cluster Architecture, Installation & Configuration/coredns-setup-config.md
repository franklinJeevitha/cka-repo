
# 🛠️ CoreDNS: Setup and Configuration

CoreDNS is a flexible, extensible DNS server that has been the default for Kubernetes since version 1.11. It runs as a **Deployment** with a **Service** in the `kube-system` namespace.



## 1. The Deployment Components
CoreDNS consists of four main parts in your cluster:
1.  **Service Accounts & RBAC:** Allows CoreDNS to read Service and Endpoint data from the K8s API.
2.  **Deployment:** Usually 2 replicas for high availability.
3.  **Service:** A ClusterIP (typically `10.96.0.10`) that Pods use as their nameserver.
4.  **ConfigMap:** The "Brain" containing the configuration (the **Corefile**).

---

## 2. The Corefile Configuration
The configuration is stored in a ConfigMap named `coredns`. It uses a "Plugin" architecture where each block defines how DNS queries are handled.

**View it with:** `kubectl get cm -n kube-system coredns -o yaml`

### **Sample Corefile Breakdown:**
```nginx
.:53 {
    errors          # Log errors to stdout
    health {        # Health check endpoint at http://localhost:8080/health
       lameduck 5s
    }
    ready           # Readiness check endpoint at http://localhost:8081/ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {  # The K8s Plugin
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153 # Metrics for scraping
    forward . /etc/resolv.conf # Forward non-cluster queries to Host DNS
    cache 30        # Cache responses for 30 seconds
    loop            # Detect simple forwarding loops
    reload          # Allow automatic config reload when CM changes
    loadbalance     # Round-robin for A records
}
```

### **Critical Plugins Explained:**
* **`kubernetes`**: The core plugin. It watches the K8s API.
    * `cluster.local`: The base domain it is responsible for.
    * `pods insecure`: Enables DNS resolution for Pods (e.g., `10-244-1-5.default.pod.cluster.local`).
* **`forward . /etc/resolv.conf`**: If you try to ping `google.com`, CoreDNS doesn't know it. This line tells it to look at the **Node's** `/etc/resolv.conf` and ask the upstream provider (like Google DNS `8.8.8.8` or AWS DNS).
* **`cache`**: Reduces the load on the API server by remembering results locally.

---

## 3. How to Update Configuration
If you need to add a custom DNS entry (e.g., pointing `my-external-db.com` to a specific IP), you edit the ConfigMap.

```bash
kubectl edit configmap coredns -n kube-system
```

**Example: Adding a Static Host**
Add the `hosts` plugin inside the `.:53` block:
```nginx
    hosts {
       192.168.1.50 my-external-db.com
       fallthrough
    }
```
*Because the `reload` plugin is active, CoreDNS will detect the change and update without a restart.*

---

## 4. Troubleshooting Setup & Connectivity

### **A. Check the Service & Endpoints**
The Service IP must match the `nameserver` entry in your Pods' `/etc/resolv.conf`.
```bash
kubectl get svc -n kube-system kube-dns
# Confirm the IP (e.g., 10.96.0.10)
```

### **B. Check CoreDNS Logs**
If DNS is failing, the logs are the first place to look for API permission errors or forwarding loops.
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### **C. The "Loop" Error**
If CoreDNS pods are crashing with a `Loop` error, it means the host's `/etc/resolv.conf` is pointing to `127.0.0.1`. CoreDNS forwards to the host, which forwards back to CoreDNS, creating a loop.
* **Fix:** Point the Node's DNS to a real upstream server (like `8.8.8.8`).

---

## 📊 CoreDNS vs. Kube-DNS (Legacy)

| Feature | CoreDNS (Modern) | Kube-DNS (Old) |
| :--- | :--- | :--- |
| **Architecture** | Single process (Go) | 3 containers per pod |
| **Configuration** | Corefile (Flexible) | Hardcoded flags |
| **Extensibility** | Middleware/Plugins | Limited |
| **Performance** | Memory efficient | Higher overhead |

---

### 💡 Practical Engineering Tip
For production clusters, consider **NodeLocal DNSCache**. It runs a small DNS caching agent on every node as a DaemonSet. This prevents "DNS Exhaustion" where thousands of Pods overwhelm the central CoreDNS pods, reducing latency significantly.
