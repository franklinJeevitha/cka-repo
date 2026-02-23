
### 1. Horizontal Pod Autoscaler (HPA)

HPA scales the **number of replicas** in a Deployment, ReplicaSet, or StatefulSet. It acts based on observed CPU utilization (or, with custom metrics, other application-provided metrics).

* **Mechanism:** The HPA controller queries the **Metrics Server** every 15 seconds (by default) to check resource utilization.
* **The Formula:**


* **Requirements:**
1. **Metrics Server:** Must be running in the cluster (`kubectl top nodes` must work).
2. **Resource Requests:** You **must** define `resources.requests` in your Pod spec. Without this, the HPA cannot calculate the percentage of utilization.



#### 🛠️ Essential Commands

* **Imperative Create:** `kubectl autoscale deployment flask-app --cpu-percent=50 --min=1 --max=10`
* **Check Status:** `kubectl get hpa`
* **Detailed View:** `kubectl describe hpa flask-app`

---

### 2. Vertical Pod Autoscaler (VPA)

VPA scales the **resource size** (CPU/Memory) of existing pods rather than the count.

* **Logic:** It monitors pods and provides recommendations for the "ideal" resource limits.
* **Modes:**
* **Off:** Only provides recommendations (lowest risk).
* **Initial:** Only assigns resources when the pod is first created.
* **Auto:** Actively evicts and restarts pods to apply new resource limits (can cause downtime).


* **Limitation:** It cannot be used on the same resource (CPU/RAM) as an HPA if the HPA is also using that resource for scaling.

---

### 3. Cluster Autoscaler (CA)

While HPA and VPA handle Pods, the **Cluster Autoscaler** handles the **Nodes**.

* **Scale Out:** Triggered when a Pod is **Pending** because no nodes have enough available resources. It requests the Cloud Provider (AWS, GCP, Azure) to add a new node.
* **Scale In:** Triggered when a node is underutilized for an extended period and all its pods can be moved to other existing nodes.

---

### 📝 Salient Points for the Exam

* **The Scaling Gap:** HPA doesn't scale instantly. There is a "Stabilization Window" (default 5 mins for scale-down) to prevent "flapping" (rapidly scaling up and down due to minor fluctuations).
* **Multiple Metrics:** You can define an HPA that looks at both CPU and Memory. The HPA will calculate the desired replica count for each and pick the **highest** value.
* **Troubleshooting HPA:**
* If HPA shows `<unknown>` under the `TARGETS` column, it usually means the **Metrics Server** is down or the Pod lacks **resource requests**.



---

## 🛠️ Comparison Table for Notes

| Feature | HPA (Horizontal) | VPA (Vertical) | Cluster Autoscaler |
| --- | --- | --- | --- |
| **Scales what?** | Number of Pods | Size of Pod (CPU/RAM) | Number of Nodes |
| **Key Trigger** | Metric Threshold (%) | Resource Exhaustion/Waste | Pending Pods |
| **Downtime?** | No | Yes (if in Auto mode) | No (but adds latency) |
| **CKA Focus** | High | Medium/Low | Low (Theory only) |
