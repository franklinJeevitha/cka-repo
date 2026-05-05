Control plane failures are critical because they affect the cluster's ability to manage resources. If the control plane is down, you cannot schedule new pods, update configurations, or scale deployments, though existing pods usually continue to run.


---

## 1. High-Level Diagnostics
The control plane consists of the **API Server**, **Scheduler**, **Controller Manager**, and **etcd**. In most managed services (EKS, GKE), this is handled for you. In self-managed clusters (kubeadm), these usually run as **Static Pods**.

### **Step 1: Check Node Status**
If the control plane node itself is `NotReady`, the components on it cannot function.
```bash
kubectl get nodes
```

### **Step 2: Check Static Pod Status**
Static pods are located in `/etc/kubernetes/manifests`. If the kubelet on the master node is healthy, it will attempt to run these pods.
```bash
# On the Master Node:
docker ps       # If using Docker runtime
crictl ps       # If using containerd (standard for modern K8s)
```



---

## 2. Component-Specific Troubleshooting

### **A. kube-apiserver (The Core)**
If the API server is down, `kubectl` commands will return "Connection Refused."
*   **Common Causes:** Expired certificates, incorrect port mapping, or etcd being unreachable.
*   **Investigation:** Check the logs directly from the container runtime since `kubectl logs` won't work.
    ```bash
    # Check logs via journalctl if running as a service
    journalctl -u kube-apiserver -f
    
    # Or check log files directly
    tail -f /var/log/pods/kube-system_kube-apiserver...
    ```

### **B. etcd**
If etcd is failing, the API server will be unable to start or process write requests.
*   **Common Causes:** Disk space full (database quota exceeded), network latency between members, or certificate mismatch.
*   **Investigation:**
    
```bash
    # Check etcd health
    ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
      --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
      endpoint health
```

### **C. kube-scheduler & kube-controller-manager**
If these fail, pods will stay in `Pending` state or deployments won't pick up changes.
*   **Common Causes:** Incorrect leader election settings or authentication failure with the API server.
*   **Investigation:** Check for "Leader Election" logs to ensure one instance has successfully claimed the lead.

---

## 3. The Kubelet: The Control Plane's Feet
The kubelet is the agent on each node. If it fails on a master node, the Static Pods (API server, etc.) will stop.
*   **Investigation:**
    
```bash
    systemctl status kubelet
    journalctl -u kubelet -n 100 # Look for "failed to pull" or "permission denied"
```



---

## 4. Common Certificate Issues
Kubernetes control plane components communicate via TLS. Expired or mismatched certificates are a top cause of failure.
*   **Check Certificate Expiry:**
    ```bash
    kubeadm certs check-expiration
    ```
*   **Renew Certificates:**
    ```bash
    kubeadm certs renew all
    ```

---

## 5. Troubleshooting Checklist

| Symptom | Primary Component to Check |
| :--- | :--- |
| `kubectl` commands time out | **kube-apiserver** |
| Pods stay `Pending` indefinitely | **kube-scheduler** |
| New replicas aren't created | **kube-controller-manager** |
| API Server logs show "database connection error" | **etcd** |
| Node is `NotReady` | **kubelet / Container Runtime** |

---

## 6. Logs & Paths (Cheat Sheet)

*   **Static Pod Manifests:** `/etc/kubernetes/manifests/`
*   **PKI/Certificates:** `/etc/kubernetes/pki/`
*   **Kubeconfig files:** `/etc/kubernetes/admin.conf`
*   **System Logs:** `journalctl -u kubelet`

---
