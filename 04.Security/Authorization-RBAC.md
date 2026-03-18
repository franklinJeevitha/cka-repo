
# 🛡️ Kubernetes Authorization (RBAC)

Authorization happens **after** a user is authenticated. It defines "Who can do what on which resource."

## 1. The Four RBAC Objects
Kubernetes uses four primary objects to manage permissions. They work in pairs:

| Level | Definition (The "What") | Assignment (The "Who") |
| :--- | :--- | :--- |
| **Namespace** | **Role**: Permissions for one namespace. | **RoleBinding**: Links a Role to a user/group in a namespace. |
| **Cluster** | **ClusterRole**: Permissions for the whole cluster. | **ClusterRoleBinding**: Links a ClusterRole to a user/group cluster-wide. |

> **Note:** A `RoleBinding` can also reference a `ClusterRole` to grant those permissions only within a specific namespace.

---

## 2. RBAC Anatomy (YAML Skeletons)

### **Role** (Namespace Scoped)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

### **RoleBinding**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: User
  name: franklin  # Name is case-sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 3. The "DevOps" Fast Track (Imperative Commands)
In the CKA exam and daily automation, avoid writing RBAC YAML from scratch. Use these generators:

```bash
# Create a Role that can manage deployments in 'staging'
kubectl create role deploy-manager --verb=get,list,create,delete --resource=deployments -n staging

# Bind that role to a user
kubectl create rolebinding dev-user-binding --role=deploy-manager --user=dev-user -n staging

# Create a ClusterRole for node monitoring
kubectl create clusterrole node-reader --verb=get,list --resource=nodes

# Check permissions (Critical for troubleshooting!)
kubectl auth can-i create deployments --as dev-user -n staging
```

---

## 4. Troubleshooting RBAC
If an application or user gets a `403 Forbidden` error:
1.  **Identify the User/ServiceAccount:** Who is making the request?
2.  **Check the Verb & Resource:** What were they trying to do? (`get pods`? `patch nodes`?)
3.  **Audit Bindings:** `kubectl get rolebindings,clusterrolebindings -A | grep <user-name>`
4.  **Test Hypotheses:** Use `kubectl auth can-i` to verify if your fix works.

---
