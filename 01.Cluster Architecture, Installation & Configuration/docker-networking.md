To understand Kubernetes networking, you must first master how Docker isolates containers on a single host. Docker uses the same Linux primitives we just discussed—**Namespaces, Bridges, and Veth pairs**—but automates the setup.

# 🐳 Docker Networking Drivers

When you install Docker, it creates three default networks. You can see them using `docker network ls`. Each driver serves a specific architectural purpose.



## 1. The Bridge Network (Default)
This is the most common driver. When you run a container without specifying a network, it joins the default `bridge` (usually named `docker0`).

* **How it works:** Docker creates a virtual bridge (`docker0`) on the host. Every container gets its own **Network Namespace** and a **veth pair** connecting it to that bridge.
* **IP Address:** Containers get a private IP (e.g., `172.17.0.x`).
* **Connectivity:** Containers on the same bridge can talk to each other via IP. To reach the outside world, Docker uses **NAT (IP Masquerading)** on the host.

```bash
# Inspect the default bridge details
docker network inspect bridge
```

---

## 2. The Host Network
In this mode, the container **does not get its own network namespace**. It shares the host's networking stack directly.

* **Pros:** Maximum performance (no NAT overhead).
* **Cons:** Port conflicts. If the container uses port 80, no other container (or the host) can use port 80.
* **Use Case:** High-performance web servers or system-level monitoring tools.

```bash
docker run --network host nginx
```

---

## 3. The None Network
The container has a loopback interface (`127.0.0.1`) but **no external network interface**. 

* **Use Case:** Batch processing jobs that don't require network access (high security/isolation).

---

## 4. User-Defined Bridge Networks
In production, we rarely use the default `docker0`. Instead, we create **User-Defined Bridges**.

**Why?**
1.  **Automatic DNS:** Containers on a user-defined bridge can talk to each other by **Container Name**. On the default bridge, they can only talk via IP.
2.  **Isolation:** Only containers on the same custom bridge can communicate.

```bash
# 1. Create a custom network
docker network create my-app-net

# 2. Run containers on that network
docker run -d --name db --network my-app-net mysql
docker run -d --name web --network my-app-net nginx

# 3. Test DNS (The 'web' container can find 'db' by name)
docker exec web ping db
```

---

## 5. Port Mapping (The "Entrance")
Since bridge IPs are private to the host, external traffic cannot reach them directly. We use **Port Mapping** (`-p`) to bridge the gap.

```bash
docker run -p 8080:80 nginx
```
* **Host Port:** 8080
* **Container Port:** 80
* **Mechanism:** Docker adds an **iptables DNAT** rule to the host's NAT table, forwarding traffic from the host's physical NIC (port 8080) to the container's virtual IP (port 80).



---

## 6. Embedded DNS
Docker runs an embedded DNS server at `127.0.0.11` inside every container. 
* It resolves container names to IPs for all containers on the same **User-Defined** network.
* If it can't find a name locally, it forwards the request to the DNS servers configured on the host (from `/etc/resolv.conf`).

---

## 💡 Practical Engineering Tips

* **Inspect is your friend:** Use `docker inspect <container_id>` and look at the `NetworkSettings` section to find the container's IP and MAC address.
* **The "Link" is Legacy:** You might see `--link` in old tutorials. **Do not use it.** User-defined networks with name resolution is the modern standard.
* **Overlay Networks:** While Bridge/Host/None are for a single host, Docker **Swarm** uses the `overlay` driver to connect containers across multiple different physical hosts. This is the closest Docker-native equivalent to Kubernetes networking.

---
