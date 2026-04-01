**IPAM** stands for **IP Address Management**. In the world of networking and Kubernetes, it is the specialized "accountant" whose only job is to keep track of which IP addresses are available, which are taken, and to whom they belong.

Within the CNI framework, IPAM is usually a **sub-plugin**. When the main CNI plugin (like `bridge` or `calico`) is told to set up a network for a Pod, it doesn't decide the IP itself—it calls the IPAM plugin to get a valid address.

---

## 1. How IPAM Works in a Cluster
Every Node in a Kubernetes cluster is assigned a **Pod CIDR** (a range of IPs). IPAM ensures that inside that range, no two Pods ever get the same IP.

### **The Workflow:**
1.  **Request:** The Kubelet calls the CNI plugin (e.g., `bridge`) to add a Pod.
2.  **Delegate:** The `bridge` plugin calls the **IPAM plugin** (e.g., `host-local`).
3.  **Allocate:** IPAM looks at its local database (or a file), finds the next free IP (e.g., `10.244.1.5`), and marks it as "In Use."
4.  **Return:** IPAM returns that IP to the `bridge` plugin, which then assigns it to the Pod's `eth0` interface.


---

## 2. Common IPAM Types
Depending on your environment, you will use different IPAM plugins:

### **A. `host-local` (The Standard)**
This is the simplest and most common for on-prem or bare-metal clusters.
* **Mechanism:** It stores the state of used IPs in a simple text file on the Node's local disk (usually under `/var/lib/cni/networks/`).
* **Scope:** It only cares about the IPs on that specific node.

### **B. `dhcp`**
* **Mechanism:** It sends a DHCP request to a server on your physical network.
* **Use Case:** When you want your Pods to have "real" IPs that are reachable from your physical office network.

### **C. Cloud-Specific (AWS VPC / Azure VNET)**
* **Mechanism:** The IPAM talks directly to the Cloud API (like AWS EC2) to reserve a "real" Private IP from the VPC.
* **Use Case:** EKS, AKS, and GKE.

---

## 3. IPAM Configuration Example
Inside your `/etc/cni/net.d/` config file, the `ipam` section defines the rules.

```json
"ipam": {
    "type": "host-local",           // The binary to execute in /opt/cni/bin/
    "subnet": "10.244.1.0/24",      // The range for THIS node
    "routes": [
        { "dst": "0.0.0.0/0" }      // Tell the pod to send all traffic to the gateway
    ],
    "rangeStart": "10.244.1.10",    // Start assigning from .10
    "rangeEnd": "10.244.1.50",      // Stop assigning at .50
    "gateway": "10.244.1.1"         // The IP of the bridge (v-net-0)
}
```

---

## 4. Troubleshooting IPAM
If your Pods are stuck in `ContainerCreating` with a "Network" error, IPAM is a likely suspect.

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| **"No addresses available"** | Your subnet is full. You tried to run 300 pods on a `/24` (254 IPs) network. | Increase the subnet size or delete old pods. |
| **Duplicate IP errors** | The local storage file is corrupted or wasn't cleaned up after a crash. | Check `/var/lib/cni/networks/` and clean up stale files. |
| **"Plugin not found"** | The `host-local` binary is missing. | Ensure it exists in `/opt/cni/bin/`. |

---

### 💡 Practical Engineering Tip
In the **CKA Exam**, you might be asked why a Pod isn't starting. If you see an error like `failed to allocate for range 0: no IP addresses available`, it means your **IPAM pool is exhausted**. This often happens in lab environments where many Pods were created and deleted rapidly without the `DEL` command properly cleaning up the IPAM files.
