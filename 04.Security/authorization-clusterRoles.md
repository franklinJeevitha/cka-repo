**ClusterRoles** are the "Global" version of RBAC in Kubernetes. While a **Role** is restricted to a single namespace (like `development`), a **ClusterRole** is cluster-wide.
---
# 🌍 Kubernetes ClusterRoles & ClusterRoleBindings

When you need to grant permissions across the **entire cluster** or for **non-namespaced resources** (like Nodes or PersistentVolumes), you use a `ClusterRole`.

## 1. When to use ClusterRole vs Role?
* **Use Role:** For specific app permissions within one namespace (e.g., "Allow a pod to read secrets in `frontend`").
* **Use ClusterRole:** * To manage cluster-wide resources (Nodes, PVs, Namespaces).
    * To manage namespaced resources across **all** namespaces (e.g., "Allow a monitoring tool to see pods in every namespace").
    * To manage non-resource URLs (like `/healthz` or `/metrics`).



---

## 2. YAML Definitions

### **ClusterRole** (No Namespace field!)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
```

### **ClusterRoleBinding**
Links the ClusterRole to a user globally.
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes-global
subjects:
- kind: User
  name: franklin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 3. CKA Exam Shortcuts (Imperative)
Efficiency is key for the CKA. Use these to generate your YAML or create objects instantly:

```bash
# Create a ClusterRole that can view all storage classes
kubectl create clusterrole storage-viewer --verb=get,list,watch --resource=storageclasses

# Bind a ClusterRole to a service account in a specific namespace
kubectl create clusterrolebinding view-all-binding --clusterrole=view --serviceaccount=default:pipeline-sa

# Pro Tip: Check what a ClusterRole can do
kubectl describe clusterrole admin
```

---

## 4. The "RoleBinding to ClusterRole" Trick
This is a frequent CKA scenario. You can use a **RoleBinding** to point to a **ClusterRole**.
* **Result:** The user gets the permissions defined in the ClusterRole, but **only within the namespace** where the RoleBinding exists.
* **Benefit:** Allows you to define common permissions (like `view-only`) once as a ClusterRole and reuse them across 50 namespaces without creating 50 individual Roles.

---

### 💡 Why this matters ?
In a **DevOps** role, you will often set up **ServiceAccounts** for cluster-wide tools:
* **Prometheus:** Needs a `ClusterRole` to scrape metrics from every pod in the cluster.
* **Cluster Autoscaler:** Needs a `ClusterRole` to see Node status and modify Auto Scaling Groups in AWS.
* **CSI Drivers (AWS EBS/EFS):** Need `ClusterRoles` to manage storage volumes across the whole AWS infrastructure.
