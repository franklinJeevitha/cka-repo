
# 🐳 Docker Security Fundamentals

Docker security relies on the Linux Kernel's ability to isolate processes. If a container is compromised, these layers prevent the attacker from "escaping" to the host machine.

## 1. Process Isolation (Namespaces)
Docker uses **Linux Namespaces** to provide the illusion of a dedicated OS to the container. Each namespace isolates a specific resource:

| Namespace | What it Isolates |
| :--- | :--- |
| **PID** | Process IDs (The container can't see processes on the host). |
| **NET** | Network stacks (The container has its own IP and routing table). |
| **MNT** | Mount points (The container has its own file system view). |
| **UTS** | Hostname and NIS domain name. |
| **IPC** | Shared memory and inter-process communication. |
| **USER** | User and Group IDs. |



---

## 2. The Root User & Control Groups (cgroups)
By default, the user inside a container is **root (UID 0)**. 
* **The Risk:** If a process runs as root in a container, it is technically the same root user as on the host. If the container isolation is bypassed, the attacker has full host control.
* **cgroups (Control Groups):** These limit **resource usage** (CPU, Memory, I/O). They ensure a single container cannot crash the host by consuming all RAM (OOM - Out of Memory).

---

## 3. Linux Capabilities (Fine-Grained Control)
The root user on a traditional Linux system is "all-powerful." Docker breaks this power into smaller pieces called **Capabilities**. Even if you are "root" in a container, Docker **drops** most dangerous capabilities by default.

### **Common Capabilities:**
* `CHOWN`: Make arbitrary changes to file UIDs and GIDs.
* `NET_BIND_SERVICE`: Bind a socket to privileged ports (below 1024).
* `NET_ADMIN`: Perform network-related operations (interface changes, routing).
* `SYS_TIME`: Modify the system clock.

---

## 4. Managing Capabilities (`--cap-add` / `--cap-drop`)
You should follow the **Principle of Least Privilege**: Drop all capabilities and add back only what is strictly necessary.

### **A. Dropping All and Adding One**
If your app only needs to change file ownership:
```bash
docker run --cap-drop=ALL --cap-add=CHOWN nginx
```

### **B. Adding Network Admin Powers**
If you are running a VPN or specialized networking tool:
```bash
docker run --cap-add=NET_ADMIN ubuntu
```

### **C. The "Dangerous" Flag: `--privileged`**
Running a container with `--privileged` gives it **all** capabilities and disables all isolation. 
> [!CAUTION] 
> **Never** use this in production unless you are running "Docker-in-Docker" or low-level system tools.

---

## 5. Security Best Practices for Dockerfiles

* **Run as Non-Root:** Always specify a user in your Dockerfile.
  ```dockerfile
  RUN useradd -u 1001 devuser
  USER devuser
  ```
* **Use Official Images:** Only pull from verified publishers to avoid "poisoned" images.
* **Scan Images:** Use `docker scan` or `trivy` to check for OS-level vulnerabilities.

---

### 💡 Why this matters for the CKA?
In Kubernetes, these Docker concepts are implemented via the **SecurityContext**. When you write a Pod YAML, you will use `capabilities: { add: ["NET_ADMIN"] }` or `runAsUser: 1000`. Understanding the Docker foundation makes the Kubernetes YAML much easier to memorize.

---
