
### 1. `kube-apiserver` vs. `kubeadm`

| Feature | `kube-apiserver` | `kubeadm` |
| --- | --- | --- |
| **Type** | **Component** (The Brain) | **Tool** (The Builder) |
| **Role** | It is the "front-end" of the cluster. Every command you run (`kubectl`) goes here. | It is the utility used to install, upgrade, and manage the cluster components. |
| **Status** | It runs 24/7 as a static pod. | It is a binary you run only when you need to perform an action (init, join, upgrade). |
| **Analogy** | The Engine of a car. | The Mechanic's specialized wrench. |

---

### 2. Why does the API Server upgrade first?

In the Kubernetes upgrade sequence, the **Control Plane (specifically the API Server)** must always be upgraded before the **Kubelet** (the agent on the nodes).

**The Reason: Backward Compatibility Logic**
The Kubernetes versioning policy follows a strict rule: **The API Server must be able to "talk" to older Kubelets, but an older API Server cannot "talk" to newer Kubelets.**

* **API Server Capability:** A v1.30 API Server is designed to understand the language of v1.29 and v1.28 Kubelets.
* **Kubelet Limitation:** A v1.29 Kubelet might send a new type of data or request a feature that a v1.28 API Server simply doesn't recognize yet.
* **Skew Rule:** The API Server is allowed to be up to **one minor version ahead** of other control plane components (Controller Manager, Scheduler) and up to **two minor versions ahead** of the Kubelets.

> **Rule of Thumb:** Always upgrade the "Brain" (API Server) so it has the intelligence to manage the "Limbs" (Kubelets) as they catch up.

---

### The "N-2" Skew Rule

Kubernetes components can exist at different versions during an upgrade. Here is the allowed "Skew":

* **`kube-apiserver`**: The baseline (X).
* **`kube-controller-manager`, `kube-scheduler**`: Can be **X-1** (one version older than API server).
* **`kubelet`**: Can be **X-2** (two versions older than API server).
* **`kubectl`**: Can be **X+1** or **X-1** (one version newer or older than API server).

---

### 🛠️ The Practical CKA Workflow

When you perform the upgrade in the exam, notice the sequence:

1. **Upgrade `kubeadm` binary**: You need the new "wrench" first.
2. **`kubeadm upgrade apply`**: This upgrades the **Control Plane static pods** (API Server is the big one here).
3. **Upgrade `kubelet**`: Finally, you upgrade the agent on the node to match the new API Server version.
