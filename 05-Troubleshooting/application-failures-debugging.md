Troubleshooting in Kubernetes is about eliminating variables. When an application fails, you must quickly differentiate between an infrastructure issue (e.g., node resource exhaustion), a configuration issue (e.g., bad environment variables), and an application-level bug (e.g., memory leaks or unhandled exceptions).

---

## 1. The Systematic Troubleshooting Workflow

When a production system goes down, follow this logical order to minimize your Mean Time To Resolution (MTTR).



### **Step 1: Inspect the Pod Lifecycle (Get Status)**
Start by identifying the state of the Pod.
```bash
# List all pods and their status in a namespace
kubectl get pods -n <namespace> -o wide
```
* **Running:** The pod is likely fine; look for network or application logic issues.
* **CrashLoopBackOff:** The container started but died immediately (look at logs).
* **ImagePullBackOff:** Registry/Tag issue or authentication failure.
* **Pending:** Resource exhaustion, unschedulable (taints), or failed PVC binding.

### **Step 2: Check Cluster Events (The "Why")**
If the pod is not `Running`, the Kubernetes event stream is your primary source of truth.
```bash
# Look for recent events related to the pod
kubectl describe pod <pod-name> -n <namespace>
```
* **Focus on the `Events` section at the bottom.** Look for warnings like `FailedScheduling`, `FailedMount`, or `BackOff`.

### **Step 3: Analyze Application Logs**
Once you confirm the pod is "Running" but throwing errors, check the logs.
```bash
# View current logs
kubectl logs <pod-name> -n <namespace>

# View previous logs (crucial for CrashLoopBackOff)
kubectl logs <pod-name> -p -n <namespace>
```

### **Step 4: Inspect Environment & Network**
If logs are inconclusive, check the runtime configuration or connectivity.
```bash
# Exec into the container to test connectivity
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Once inside, test dependencies
curl <database-service-dns>:5432
```

---

## 2. Common Failure Patterns Table

| Status | Likely Cause | Investigation Path |
| :--- | :--- | :--- |
| **CrashLoopBackOff** | Application exit code > 0 | Check `logs -p`. Is it a missing secret, bad config, or OOMKilled? |
| **ImagePullBackOff** | Registry access/Tag error | `kubectl describe pod`. Verify image exists/credentials. |
| **Pending** | No nodes/Insufficient resources | `kubectl describe pod`. Look for "Insufficient CPU/Memory". |
| **Terminating** | Finalizers or Graceful shutdown | `kubectl get pod -o yaml`. Check `finalizers` field. |
| **OOMKilled** | Memory limit exceeded | Check `describe pod`. Look for `Last State: Terminated` with `reason: OOMKilled`. |

---

## 3. Advanced Troubleshooting Techniques

### **A. Ephemeral Containers (`kubectl debug`)**
If your container is "distroless" (has no shell/curl), you cannot use `exec`. Use ephemeral containers to attach a debugging container to the pod's namespace.
```bash
kubectl debug -it <pod-name> --image=busybox --target=<container-name>
```

### **B. Port Forwarding**
If you need to hit the application directly from your local machine to bypass Ingress/LoadBalancer issues.
```bash
kubectl port-forward pod/<pod-name> 8080:80
```

### **C. Resource Usage Analysis**
If your application crashes under load, check resource saturation.
```bash
# Check node resource utilization
kubectl top nodes

# Check pod resource utilization
kubectl top pods -n <namespace>
```

---

## 4. The SRE "Golden Path" for Debugging

If you are stuck, run through these four questions in order:

1.  **Is the Pod scheduled?** (If `Pending`, check resources/taints).
2.  **Is the Container crashing?** (If `CrashLoopBackOff`, check `logs -p` or startup commands).
3.  **Is the Application failing to respond?** (If `Running` but returning `5xx` errors, check logs for connection timeouts or database errors).
4.  **Is the Network blocking traffic?** (Check `NetworkPolicies` or Service Selector/Endpoint mapping).

---

### 💡 Pro-Tip: The "ConfigMap Change" Gotcha
In Kubernetes, updating a `ConfigMap` used as an environment variable does **not** trigger a rolling update of the Pod. If you update a config and the application doesn't pick it up, you must manually delete the pod or use a tool (like Helm or a deployment annotation) to force a restart.
