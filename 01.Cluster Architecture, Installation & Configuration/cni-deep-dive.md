
# 🔌 CNI (Container Network Interface)

The CNI is a CNCF project consisting of a **specification** and **libraries** for writing plugins to configure network interfaces in Linux containers. Kubernetes uses CNI to manage pod networking across a distributed cluster.



## 1. Why CNI? (The "Plug-and-Play" Model)
Kubernetes does not have its own built-in networking. Instead, it defines a standard "socket" (the CNI). Any vendor (Calico, Cilium, Flannel) can create a "plug" (the CNI Plugin) that follows the spec.

* **Responsibility of the CNI:**
    1.  Create the Network Namespace for the Pod.
    2.  Insert a network interface (veth pair) into the namespace.
    3.  Connect the other end of the veth pair to the host bridge or routing mesh.
    4.  Assign an IP address to the interface (via the IPAM plugin).
    5.  Setup routes and clean up when the Pod is deleted.

---

## 2. The Kubelet-CNI Interaction
When a Pod is scheduled on a node, the **Kubelet** doesn't know how to set up the network. It looks at the `--cni-bin-dir` (usually `/opt/cni/bin`) and `--cni-conf-dir` (usually `/etc/cni/net.d`).

1.  **Kubelet** identifies the Pod's namespace.
2.  **Kubelet** calls the CNI binary (e.g., `./calico`) with the command `ADD`.
3.  **CNI Plugin** executes the Linux networking commands (like the `ip netns` commands we practiced).
4.  **CNI Plugin** returns a JSON response containing the IP and interface details to the Kubelet.

---

## 3. IPAM (IP Address Management)
A sub-component of CNI is **IPAM**. Its only job is to manage the pool of available IP addresses (the Pod CIDR) and ensure no two pods on the node get the same IP.

* **host-local:** Assigns IPs from a pre-defined range on the local node.
* **dhcp:** Requests an IP from an external DHCP server.



---

## 4. Popular CNI Plugins (Selection Guide)

| CNI Plugin | Primary Feature | Best Use Case |
| :--- | :--- | :--- |
| **Flannel** | Extremely simple L2 overlay. | Small clusters, learning/testing. No Network Policy support. |
| **Calico** | L3 routing, high performance. | Production. Known for industry-standard **Network Policy** enforcement. |
| **Cilium** | Uses **eBPF** (Linux Kernel tech). | High-scale, security-focused, and "sidecar-less" service mesh. |
| **AWS/Azure/GCP CNI** | Cloud-native integration. | EKS/AKS/GKE. Assigns real VPC IPs to Pods for direct cloud access. |

---

## 5. Troubleshooting CNI (The "Node NotReady" fix)
If a Node is in `NotReady` status, the CNI is often the culprit.

```bash
# 1. Check the Kubelet logs for CNI errors
journalctl -u kubelet | grep -i cni

# 2. Check the CNI config file on the node
cat /etc/cni/net.d/*.conflist

# 3. Check the binary directory
ls /opt/cni/bin/
# If this is empty, your CNI plugin (e.g., Calico pods) failed to install them.
```

---

## 💡 Practical Engineering Tips

* **The MTU Issue:** If you can ping between pods, but large data transfers (like a database sync) fail or "hang," it is almost always an **MTU (Maximum Transmission Unit)** mismatch. Overlay networks (VXLAN) add headers to packets, so you may need to lower the MTU in your CNI config.
* **Overlay vs. Underlay:** * **Overlay (Flannel/Calico VXLAN):** Wraps pod packets inside host packets. Works anywhere, but has a small performance hit.
    * **Underlay/Routing (Calico BGP):** Routes pod packets directly. Maximum performance, but requires network hardware support (BGP).

---
