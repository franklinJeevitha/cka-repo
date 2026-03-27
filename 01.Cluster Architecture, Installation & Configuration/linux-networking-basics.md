These notes bridge the gap between "standard Linux" and how Kubernetes handles traffic between nodes and pods. Understanding the **Host Level** networking is the foundation for troubleshooting "Node NotReady" or "Pod Connection Timeout" issues.

# 🌐 Linux Networking Fundamentals

Before Kubernetes can network Pods, the underlying Linux OS must handle switching, routing, and DNS. These are the "low-level" mechanics of how packets move.

## 1. Switching & Bridges
In a physical network, a **Switch** connects devices in the same network. In Linux, we use a **Virtual Bridge**.

* **The Bridge (`br0`):** Acts as a virtual switch. It allows multiple virtual interfaces (like those for Containers or VMs) to talk to each other as if they were on the same physical wire.
* **The "veth" pair:** Think of this as a virtual patch cable. One end stays in the Container/Pod namespace, and the other end connects to the Bridge.



---

## 2. Routing & Default Gateway
If a packet is destined for an IP address *outside* the local network, the OS looks at the **Routing Table**.

* **The Routing Table:** A list of rules that tell the OS where to send traffic based on the destination IP.
* **The Default Gateway:** This is the "exit door." If no specific route matches the destination, the packet is sent to the Default Gateway (usually the router's IP).

---

## 3. Essential Commands (The "ip" Suite)
Modern Linux uses the `iproute2` package. Avoid using legacy commands like `ifconfig` or `route` in production or exams.

### **Interfaces & Links**
```bash
# List all network interfaces (up or down)
ip link

# View IP addresses assigned to interfaces
ip addr

# Bring an interface up or down
ip link set eth0 up
```

### **Routing Table**
```bash
# View the routing table
ip route

# Add a specific route to a network
# Format: ip route add <network/mask> via <gateway>
ip route add 192.168.1.0/24 via 10.0.0.1

# Add a Default Gateway
ip route add default via 192.168.1.1
```

### **ARP (Address Resolution Protocol)**
ARP maps IP addresses to MAC addresses.
```bash
# View the ARP table (who is on my local wire?)
ip neigh
```



---

## 4. DNS & Name Resolution
In Linux, name resolution is handled by a few key files:

* **/etc/hosts:** The local "phonebook." This is checked **before** DNS. If you add `1.2.3.4 google.com` here, your machine will go to that IP for Google.
* **/etc/resolv.conf:** Tells the OS which DNS servers to ask (e.g., `nameserver 8.8.8.8`).
* **/etc/nsswitch.conf:** Defines the **order** of lookup (usually "files" first, then "dns").

---

## 5. Troubleshooting "Gotchas"

| Problem | Likely Command to Fix/Check |
| :--- | :--- |
| **Can't ping local host** | `ip addr` (Is the IP on the right subnet?) |
| **Can't reach the Internet** | `ip route` (Is there a `default` gateway?) |
| **Can reach IP but not URL** | `cat /etc/resolv.conf` (Are DNS servers correct?) |
| **Packets dropping between pods** | `iptables -L` or `nft list ruleset` (Is the firewall blocking it?) |

---

### 💡 Practical Engineering Tips

* **IP Forwarding:** For a Linux machine to act as a router (which a Kubernetes Node must do to pass traffic to Pods), **IP Forwarding** must be enabled. 
    * Check: `cat /proc/sys/net/ipv4/ip_forward` (should be `1`).
* **The Exam Trap:** If you're asked to fix a node that can't talk to the API server, always check `ip route` first. If the default gateway is missing or wrong, the node is effectively isolated.

---
