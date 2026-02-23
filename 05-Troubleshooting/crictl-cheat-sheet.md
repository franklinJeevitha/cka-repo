In the CKA exam, you might encounter a node where `kubectl` isn't working because the **Kubelet** is down. To debug, you have to go "under the hood" to the container runtime. Since modern Kubernetes uses the **CRI (Container Runtime Interface)**, `crictl` is the tool you must use—**not** `docker`.

---

### 1. The Core Purpose

`crictl` provides a CLI for CRI-compatible container runtimes (like `containerd` or `CRI-O`). It is used strictly for **node-level troubleshooting**.

* **Scope:** It only sees containers on the **local node** you are logged into.
* **Format:** The output looks very similar to Docker, but it distinguishes between **Pods** and **Containers**.

---

### 2. Configuration (The First Step)

Before `crictl` works, it needs to know where the runtime socket is. In the exam, if `crictl` fails, check the config file:

* **File Path:** `/etc/crictl.yaml`
* **Common Content:**

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false

```

---

### 3. Essential Commands for the Exam

These are the direct equivalents to `kubectl` or `docker` commands.

| Task | Command |
| --- | --- |
| **List Pods** | `crictl pods` |
| **List Containers** | `crictl ps -a` |
| **Inspect Image** | `crictl images` |
| **Container Logs** | `crictl logs <container-id>` |
| **Execute Command** | `crictl exec -it <container-id> sh` |
| **Inspect Pod** | `crictl inspectp <pod-id>` |
| **Inspect Container** | `crictl inspect <container-id>` |

---

### 4. Troubleshooting Workflow with `crictl`

If a Pod is stuck in `ContainerCreating` or `Pending` and `kubectl describe` isn't giving you enough info:

1. **SSH** into the affected node.
2. **Check Pod Status:** `crictl pods` (Look for the Pod Name and ID).
3. **Identify the Container:** `crictl ps --pod <pod-id>` (This isolates the containers for that specific pod).
4. **Check for Failures:** `crictl inspect <container-id>` (Look at the `lastTerminationState` or `exitCode`).
5. **Check Logs:** If the container is crashing, `crictl logs <container-id>` will show you the application-level errors even if `kubectl` can't reach the node.

---

## 📝 Salient Points for your Notes

* **Sandboxes:** In `crictl`, a Pod is referred to as a "Pod Sandbox."
* **No "Run" Command:** You generally don't use `crictl` to *create* containers in the exam (you use `kubectl` for that). You only use it to **view** and **debug**.
* **The ID Trap:** `crictl` uses long hex IDs. You can usually just type the first 4–5 characters of the ID (just like Docker).
* **Runtime Endpoints:** If `/etc/crictl.yaml` is missing, you can manually point to the socket:
`crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps`

---

### 🛠️ Example: Finding the Log Path

If you need to find where the actual log file lives on the disk (e.g., to grep something huge):

```bash
crictl inspect <container-id> | grep logPath

```

This will point you to something like `/var/log/pods/<namespace>_<name>_<uid>/<container>/0.log`.
