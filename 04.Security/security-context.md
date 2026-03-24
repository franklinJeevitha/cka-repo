
## 🛡️ Kubernetes Security Contexts

A `securityContext` defines privilege and access control settings for a Pod or Container. It allows you to implement the **Principle of Least Privilege** by restricting what a process can do.

### 1. Pod-Level vs. Container-Level
You can define security settings at two levels. If settings overlap, the **Container-level** setting takes precedence.

* **Pod-Level:** Applied to all containers in the pod (e.g., `runAsUser`).
* **Container-Level:** Applied only to a specific container (e.g., `capabilities`, `privileged`, `readOnlyRootFilesystem`).

---

### 2. Key Security Settings

#### **A. User and Group IDs (`runAsUser` / `runAsGroup`)**
Ensures the container does not run as the root user (UID 0).
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000      # All containers run as user 1000
    runAsGroup: 3000     # All containers run as group 3000
    fsGroup: 2000        # Files created in volumes will belong to group 2000
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
```

#### **B. Linux Capabilities (`capabilities`)**
Add or remove specific kernel-level permissions (Container-level only).
```yaml
spec:
  containers:
  - name: network-tool
    image: busybox
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
        drop: ["ALL"] # Best practice: Drop all, then add back only what is needed
```

#### **C. Read-Only Root Filesystem**
Prevents attackers from installing malicious software or modifying config files if they break into the container.
```yaml
securityContext:
  readOnlyRootFilesystem: true
```

#### **D. Privilege Escalation**
Prevents a process from gaining more privileges than its parent process (controls the `setuid` binary behavior).
```yaml
securityContext:
  allowPrivilegeEscalation: false
```

---

### 3. The "Privileged" Mode
Setting `privileged: true` is equivalent to having all capabilities and accessing all devices on the host. 
> [!CAUTION] 
> In a production environment, this should be blocked by **Admission Controllers** or **Policies** unless strictly required for system-level tools (like CNI plugins).

---

### 4. Troubleshooting & Validation
To verify if your security context is working, "exec" into the pod and check the ID or capabilities:

```bash
# Check the current user UID
kubectl exec <pod-name> -- id

# Check if the filesystem is truly read-only
kubectl exec <pod-name> -- touch /test-file
# Result should be: "touch: /test-file: Read-only file system"
```

---

### 💡 Practical Engineering Tips

* **fsGroup Power:** If you mount a volume (like an AWS EBS volume) and your container user (UID 1000) can't write to it, setting `fsGroup: 1000` tells Kubernetes to automatically change the permissions of that volume so your user can write.
* **Non-Root Requirement:** Many enterprise clusters (and CKS exam scenarios) use a policy that requires `runAsNonRoot: true`. If this is set and your image tries to run as root, the pod will fail to start.

---
