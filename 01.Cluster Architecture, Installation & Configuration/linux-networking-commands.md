
# 🛠️ Deep Dive: Linux Networking Commands & Flags

## 1. The `ip` Suite (Layer 2/3)
The `ip` command is the modern replacement for `ifconfig`.

### **A. `ip addr show`**
Lists IP addresses and property information.
* **Flags:** None usually needed, but `-c` adds color for readability.
* **Sample Output:**
```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    link/ether 08:00:27:8d:c3:52 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.10/24 brd 192.168.1.255 scope global eth0
       valid_lft forever preferred_lft forever
```
* **How to read it:**
    * **`eth0`**: Interface name.
    * **`UP`**: Software is enabled.
    * **`LOWER_UP`**: Hardware cable/link is connected.
    * **`inet 192.168.1.10/24`**: The IPv4 address and CIDR mask.
    * **`link/ether`**: The MAC (Hardware) address.

### **B. `ip route show default`**
Shows how the system sends traffic to the outside world.
* **Sample Output:**
```text
default via 192.168.1.1 dev eth0 proto dhcp metric 100
```
* **How to read it:**
    * **`default`**: Matches any IP not on your local network.
    * **`via 192.168.1.1`**: The Next Hop (Your Router/Gateway).
    * **`dev eth0`**: The exit interface.

---

## 2. The Socket Suite (Layer 4)
These tools show you what "doors" (ports) are open on your server.

### **A. `netstat -nplt`**
* **`-n` (Numeric)**: Shows port numbers (e.g., `80`) instead of names (e.g., `http`). **Crucial** for speed; DNS lookups for names can hang the command.
* **`-p` (Program)**: Shows the PID and name of the process owning the socket.
* **`-l` (Listening)**: Filters out active connections to show only services waiting for new ones.
* **`-t` (TCP)**: Limits output to TCP (the most common protocol for K8s apps).
* **Sample Output:**
```text
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:6443            0.0.0.0:* LISTEN      1234/kube-apiserver 
```


### **B. `netstat -anp`**
* **`-a` (All)**: Shows both listening and established (active) connections.
* **Sample Output:**
```text
tcp        0      0 192.168.1.10:5432       192.168.1.15:45232      ESTABLISHED 5678/postgres
```
* **How to read it:** This shows a specific client (`192.168.1.15`) is currently connected to your Database (`5432`).

---

## 3. The Modern Alternative: `ss`
`ss` is faster than `netstat` because it gets data directly from the kernel.

### **`ss -tulpn`**
* **`-t`**: TCP
* **`-u`**: UDP (Crucial for DNS/CoreDNS troubleshooting!)
* **`-l`**: Listening
* **`-p`**: Process
* **`-n`**: Numeric
* **Sample Output:**
```text
Netid  State      Recv-Q Send-Q    Local Address:Port    Peer Address:Port   Process                                          
udp    UNCONN     0      0         127.0.0.1:53          0.0.0.0:* users:(("coredns",pid=1122,fd=8))
```
* **How to read it:** `UNCONN` in UDP is the equivalent of `LISTEN` in TCP. Here, CoreDNS is listening for DNS queries on Port 53.

---

## 4. Diagnostic & Connectivity Tools

### **A. `nc -zv <IP> <Port>` (Netcat)**
* **`-z` (Zero-I/O)**: Scans for a listening daemon without sending any data.
* **`-v` (Verbose)**: Tells you if the connection succeeded or failed.
* **Sample Output:**
```text
Connection to 10.96.0.1 443 port [tcp/https] succeeded!
```

### **B. `dig <hostname>`**
* **Sample Output:**
```text
;; ANSWER SECTION:
kubernetes.default.svc.cluster.local. 30 IN A 10.96.0.1
```
* **How to read it:** The "A" record tells you the IPv4 address. The `30` is the TTL (Time to Live) in seconds.

---

## 📊 Quick Reference Table for Flags

| Command | Key Flags | Why use them? |
| :--- | :--- | :--- |
| **`ip`** | `-c` | Colorize output for faster visual scanning. |
| **`netstat/ss`** | **`-n`** | **Always use -n.** It prevents slow DNS lookups on port names. |
| **`netstat/ss`** | **`-p`** | Essential for finding *which* container/process is using a port. |
| **`tcpdump`** | `-nn` | Disables name resolution for both IPs and Ports (essential for speed). |
| **`tcpdump`** | `-i any` | Listen on all interfaces simultaneously. |



---

### 💡 Pro-Tip 
If you run `netstat -p` or `ss -p` and the "Process" column is empty, it means you aren't running as `root/sudo`. Always use `sudo` with these commands to see the process names, otherwise, you're only getting half the story.
