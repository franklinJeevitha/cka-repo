In the CKA exam, you will see `kube-proxy` running as a **DaemonSet** in the `kube-system` namespace.

### 1. What is `kube-proxy`?

If the **kube-apiserver** is the "Brain" and the **kubelet** is the "Limb," then **kube-proxy** is the **"Traffic Cop."**

* **Role:** It manages the network rules on each node.
* **Function:** It is responsible for implementing the **Service** concept. When you send traffic to a ClusterIP, `kube-proxy` is what actually directs that traffic to the correct Pod IP.
* **How it works:** It constantly watches the API Server for new Services or Endpoints. It then updates the node's **iptables** or **IPVS** rules to ensure traffic reaches its destination.

---

### 2. Version Skew: Where does it fit?

In the upgrade sequence, `kube-proxy` must be the same version as the **Kubelet** or older than the **API Server**.

* **Rule:** `kube-proxy` version must be the **same** as the Kubelet version.
* **Skew:** It can be up to **two minor versions older** than the `kube-apiserver`.

**Example:**

* If API Server is **v1.30**
* Kubelet can be **v1.28**
* Kube-proxy should be **v1.28**

---

### 3. Why did it skip the `kubeadm` manual upgrade?

When you run `kubeadm upgrade apply`, it automatically updates the **kube-proxy DaemonSet manifest**. Because it is a DaemonSet, once the manifest is updated in the cluster, the pods will restart themselves with the new version. You don't usually have to manually `apt-get install` it like you do with the Kubelet.

---

## 📝 Updated Component Comparison Table

| Component | How it runs | Upgraded By | Main Job |
| --- | --- | --- | --- |
| **Kubelet** | System Service (Systemd) | `apt-get install` | Manages containers on the node. |
| **Kube-proxy** | DaemonSet (Pods) | `kubeadm upgrade apply` | Manages networking/Service rules. |
| **API Server** | Static Pod | `kubeadm upgrade apply` | The central communication hub. |

---

### ⚠️ Exam Tip: Troubleshooting `kube-proxy`

If you can reach a Pod by its **IP**, but you **cannot** reach it via its **Service name/ClusterIP**, the problem is almost always `kube-proxy` or `CoreDNS`.

* **Check logs:** `kubectl logs -n kube-system <kube-proxy-pod-name>`
* **Check rules:** Look for `iptables -L -t nat` on the node to see if the Service rules actually exist.
