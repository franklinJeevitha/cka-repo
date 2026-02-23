In-place Pod Resizing is a relatively new and highly significant feature (introduced as Alpha in v1.27, moved to Beta in v1.32). It solves the "Restart Problem": previously, changing a Pod's CPU or Memory required a full Pod recreation. Now, you can resize resources **without** restarting the container.
---
### 1. The Core Concept

Before this feature, Pod `resources` were immutable. With In-place Resizing, the `resources` field in `pod.spec.containers` remains immutable, but a new field called **`resizePolicy`** and the ability to patch **`allocatedResources`** allows for dynamic adjustment.

* **No Restart:** The container process continues running while the underlying Cgroups (Linux control groups) are updated.
* **Requirements:**
* The Feature Gate `InPlacePodVerticalScaling` must be enabled (on older versions).
* The **CRI (Container Runtime Interface)** must support it (e.g., `containerd` v1.6.9+ or `CRI-O`).



---

### 2. The `resizePolicy`

You can define how each resource (CPU/Memory) should be handled when a change is requested.

* **`RestartContainer`**: The container is restarted to apply the new limit (traditional behavior).
* **`NotRequired`**: (Default) Kubernetes attempts to resize the resource without restarting the container.

#### 🛠️ YAML Example

```yaml
spec:
  containers:
  - name: my-app
    image: nginx
    resizePolicy:
    - resourceName: cpu
      restartPolicy: NotRequired
    - resourceName: memory
      restartPolicy: NotRequired
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"

```

---

### 3. The Resize Workflow

1. **Request:** You patch the Pod's `resources` using `kubectl patch`.
2. **Observation:** The Control Plane checks if the Node has enough capacity.
3. **Update:** * If capacity exists, the Kubelet updates the container's Cgroups.
* The `pod.status.containerStatuses[].allocatedResources` reflects the change.


4. **Actualization:** The `pod.status.containerStatuses[].resources` shows what is currently in effect.

---

## 📝 Salient Points for the Exam/Interview

* **Memory Shrinking:** Shrinking memory is riskier than expanding it. If you lower the memory limit below the application's current usage, the container may be **OOMKilled** (Out of Memory) even if `NotRequired` is set.
* **Pending Status:** If you request an increase and the node is full, the Pod will stay in its current size. The `status` field will indicate `Proposed` or `InProgress` until resources become available.
* **Interaction with VPA:** This is the "Gold Standard" for **Vertical Pod Autoscalers**. VPA can now scale your apps vertically without causing the downtime associated with Pod restarts.

---

## 🛠️ Validation & Commands

**Patch a Pod to increase CPU:**

```bash
kubectl patch pod my-app --patch '{"spec":{"containers":[{"name":"my-app","resources":{"requests":{"cpu":"500m"},"limits":{"cpu":"500m"}}}]}}'

```

**Check the resize status:**

```bash
kubectl get pod my-app -o jsonpath='{.status.containerStatuses[0].allocatedResources}'

```
