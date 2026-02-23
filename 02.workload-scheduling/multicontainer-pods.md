Multi-container pods are a key concept in the CKA exam, specifically under the **Workloads & Scheduling** domain. The fundamental rule is that all containers in a single Pod share the same **Network namespace** (IP and Port space) and can share **Storage volumes**.

---

### 1. The Three Common Patterns

While Kubernetes doesn't technically differentiate between these in code, the CKA exam expects you to understand these architectural patterns:

| Pattern | Purpose | Example |
| --- | --- | --- |
| **Sidecar** | Enhances or extends the main container. | A logging agent that collects logs from the main app and sends them to a server. |
| **Adapter** | Standardizes output from the main container. | Converting proprietary monitoring metrics into a format Prometheus understands. |
| **Ambassador** | Acts as a proxy for external connections. | A container that handles database connection logic so the app just connects to `localhost`. |

---

### 2. Shared Resources (The "How")

* **Network:** Containers communicate with each other via `localhost`. If the main app is on port 8080 and the sidecar is on 9000, they can simply "see" each other.
* **Storage:** To share data (like a log file), you must define a `volume` at the Pod level and mount it in **both** containers.

#### 🛠️ YAML Example: Shared Log Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-example
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}  # Shared storage in RAM/Disk
  containers:
    - name: main-app
      image: busybox
      command: ["sh", "-c", "while true; do echo $(date) >> /var/log/app.log; sleep 5; done"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log
    - name: sidecar-logger
      image: busybox
      command: ["sh", "-c", "tail -f /var/log/app.log"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log

```

---

### 3. Init Containers (A Special Architecture)

Init containers run **before** the main app containers start. They are used for setup logic (e.g., waiting for a database to be ready or downloading a configuration).

* **Sequential Execution:** If you have multiple init containers, they run one at a time. If one fails, the Pod restarts (depending on `restartPolicy`).
* **Completion:** The main containers only start if **all** init containers exit successfully (`exit 0`).

---

## 📝 Salient "Gotchas" for your Notes

* **The Log Command:** If you run `kubectl logs <pod-name>`, it will fail if the pod has multiple containers. You **must** use:
`kubectl logs <pod-name> -c <container-name>`
* **Port Conflicts:** Since they share an IP, two containers in the same pod **cannot** listen on the same port (e.g., both cannot use port 80).
* **Resource Limits:** The Pod's total resource request/limit is effectively the sum of all containers' requests/limits.
* **Readiness/Liveness:** Each container has its own probes. If one container's liveness probe fails, that specific container is restarted, not necessarily the whole pod.

---

## 🛠️ Validation Commands

* **Check container status:** `kubectl describe pod <name>` (Look at the `Containers` and `Init Containers` sections).
* **Interact with one container:** `kubectl exec -it <pod-name> -c <container-name> -- sh`
