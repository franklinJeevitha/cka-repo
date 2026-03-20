In the CKA exam and real-world 2026 infrastructure, the way we handle **ServiceAccounts** has evolved. 
We have moved away from "forever secrets" to **Short-lived, Projected Tokens**.

---

# 🤖 ServiceAccounts & Tokens (2026 Standards)

ServiceAccounts (SA) provide an identity for processes running inside Pods. In modern Kubernetes (v1.24+), tokens are no longer stored as static Secrets by default; they are dynamic and ephemeral.

## 1. The Default ServiceAccount
Every namespace is created with a ServiceAccount named `default`.
* **Automatic Assignment:** If you don't specify `serviceAccountName` in a Pod spec, it gets the `default` SA.
* **Permissions:** By default, it has **zero** privileges (other than basic API discovery).
* **Security Risk:** If you grant the `default` SA high permissions, **any** pod in that namespace can act as an admin. **Best Practice:** Always create a dedicated SA for your application.

---

## 2. Modern Token Management
Since K8s 1.22+, we use **Bound Service Account Tokens**. 

### **A. Projected Volumes (Internal Apps)**
Kubernetes no longer just "pastes" a secret into your pod. It uses a **Projected Volume** that communicates with the `TokenRequest` API to rotate tokens automatically.



**How to see it in a running Pod:**
```bash
# Check the mounts of a pod to see the projected token
kubectl get pod <pod-name> -o yaml | grep -A 10 volumeMounts
# Path is usually: /var/run/secrets/kubernetes.io/serviceaccount/token
```

### **B. Manual Token Generation (Short-lived)**
If you need a token for a script or a quick test:
```bash
# Generates a token valid for 1 hour (default)
kubectl create token <sa-name>

# Generates a token valid for 24 hours
kubectl create token <sa-name> --duration=24h
```

---

## 3. Using ServiceAccounts Externally
Sometimes an application **outside** the cluster (e.g., a legacy VM or a local script) needs to talk to the K8s API.

### **Option A: The "Static Secret" (Legacy/Manual)**
If you absolutely need a long-lived token (not recommended for production), you must manually create a Secret linked to the SA:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: external-app-secret
  annotations:
    kubernetes.io/service-account.name: "my-service-account"
type: kubernetes.io/service-account-token
```

### **Option B: Workload Identity (The 2026 Standard)**
For AWS (EKS), we use **IRSA (IAM Roles for Service Accounts)**. 
1. The K8s SA is annotated with an AWS IAM Role ARN.
2. The Pod receives a token via a projected volume.
3. The application uses the **AWS SDK**, which automatically exchanges the K8s token for temporary AWS credentials.

---

## 4. Summary Checklist
* [ ] **Disable Automount:** If a pod doesn't need the API, set `automountServiceAccountToken: false`.
* [ ] **Least Privilege:** Never bind `cluster-admin` to the `default` service account.
* [ ] **Audience Scoping:** Use the `--audience` flag when creating tokens to ensure they can't be reused by other services.

```bash
# Example of audience-scoped token for an external vault
kubectl create token my-sa --audience="vault-auth-service"
```
