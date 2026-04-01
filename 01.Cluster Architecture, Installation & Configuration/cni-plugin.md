To fully understand how a **CNI (Container Network Interface)** plugin functions, you have to look at it as a "middleman" between the Kubernetes **Kubelet** and the Linux **Kernel**.
---

# 🔌 CNI Plugin: Mechanism and Configuration

The CNI is not a service or a daemon; it is an **executable binary**. When a Pod is created, the Kubelet calls this binary to "wire up" the container's networking.

## 1. The Execution Workflow
When a Pod is scheduled to a node, the following sequence occurs:

1.  **Kubelet** detects a new Pod.
2.  **Kubelet** looks into `/etc/cni/net.d/` to find the JSON configuration file.
3.  **Kubelet** identifies the binary to run from the JSON (e.g., `bridge`, `calico`).
4.  **Kubelet** executes the binary located in `/opt/cni/bin/` and passes parameters via **Environment Variables**.

### **Key Environment Variables passed to the Binary:**
* `CNI_COMMAND`: Usually `ADD` (create network) or `DEL` (remove network).
* `CNI_CONTAINERID`: The unique ID of the container.
* `CNI_NETNS`: The path to the network namespace (e.g., `/proc/1234/ns/net`).
* `CNI_IFNAME`: The name of the interface to create inside the pod (usually `eth0`).



---

## 2. The CNI Configuration File (`.conflist`)
The configuration is stored in JSON format. It tells the CNI how to behave (which bridge to use, which IP range to assign).

**Location:** `/etc/cni/net.d/10-mynet.conflist`

```json
{
  "cniVersion": "0.4.0",
  "name": "mynet",
  "plugins": [
    {
      "type": "bridge",             // The main CNI binary to run
      "bridge": "cni0",             // Name of the bridge on the host
      "isGateway": true,            // Act as the default gateway for pods
      "ipMasq": true,               // Enable NAT (IP Masquerading)
      "ipam": {                     // IP Address Management sub-plugin
        "type": "host-local",       // Manage IPs locally on this host
        "subnet": "10.244.1.0/24",  // The Pod CIDR for this specific node
        "routes": [
          { "dst": "0.0.0.0/0" }    // Default route for all pod traffic
        ]
      }
    },
    {
      "type": "portmap",            // Chained plugin for port forwarding
      "capabilities": {"portMappings": true}
    }
  ]
}
```

### **Field Breakdowns:**
* **`type`**: The name of the actual binary file in `/opt/cni/bin/`.
* **`ipam`**: A nested configuration for the IP Address Management plugin. It ensures no two pods on the same node get the same IP.
* **`plugins` (List)**: CNI allows "chaining." In the example above, the `bridge` plugin runs first to set up the IP, then the `portmap` plugin runs to handle `-p` port mappings.

---

## 3. The Binary Directory (`/opt/cni/bin`)
If you look inside this folder on a Kubernetes node, you will see several small, single-purpose binaries:

* **`bridge`**: Creates a bridge and adds veth pairs to it.
* **`loopback`**: Configures the `127.0.0.1` interface.
* **`host-local`**: A standard IPAM plugin that keeps track of used IPs in a local file.
* **`calico` / `flannel`**: Vendor-specific binaries that handle multi-node routing.



---

## 4. Deep Dive: The `ADD` Command Output
When the Kubelet runs the CNI plugin with `CNI_COMMAND=ADD`, the plugin must return a JSON response so the Kubelet knows what happened.

**Sample Successful Output:**
```json
{
    "cniVersion": "0.4.0",
    "interfaces": [
        {"name": "eth0", "sandbox": "/proc/1234/ns/net"}
    ],
    "ips": [
        {
            "version": "4",
            "address": "10.244.1.5/24",
            "gateway": "10.244.1.1",
            "interface": 0
        }
    ]
}
```
**Explanation of output:**
* **`interfaces`**: Confirms that `eth0` was created inside the pod's namespace.
* **`ips`**: Tells Kubernetes that the Pod now owns `10.244.1.5`. The Kubelet will then update the Pod status so other components (like Kube-Proxy) know where to send traffic.

---

## 📊 Summary Troubleshooting Table

| If you see this error... | Check this... |
| :--- | :--- |
| `NetworkPluginNotReady` | Check if `/etc/cni/net.d/` contains a valid `.conflist` file. |
| `failed to find plugin "calico"` | Check if the binary exists in `/opt/cni/bin/`. |
| Pods stuck in `ContainerCreating` | Check Kubelet logs (`journalctl -u kubelet`) for CNI `ADD` errors. |
| No IP assigned to Pod | Check the `ipam` section of the config for subnet exhaustion. |

---

### 💡 Practical Engineering Tip
In the CKA exam, if you are asked to install a CNI plugin, you usually apply a YAML file (like `kubectl apply -f calico.yaml`). This YAML creates a **DaemonSet**. That DaemonSet runs a pod on every node which **automatically copies** the binaries into `/opt/cni/bin` and writes the config into `/etc/cni/net.d`. If the CNI isn't working, check those pods first!
