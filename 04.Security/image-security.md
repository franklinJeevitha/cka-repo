For **Image Security**, the focus is on ensuring that only trusted, scanned, and authorized containers run in your cluster. In the CKA exam and a professional DevOps environment, this usually centers on **Admission Controllers** and **Private Registries**.

---

# 🛡️ Image Security

Container images are the foundation of your workload. Securing them involves two main steps: ensuring the image itself is safe and ensuring the cluster only pulls from trusted sources.

## 1. Using Private Registries
If your images are stored in a private repository (like AWS ECR, Docker Hub Private, or Azure ACR), Kubernetes needs credentials to pull them.

### **The imagePullSecrets Method**
1. **Create the Secret:**
   ```bash
   kubectl create secret docker-registry my-registry-key \
     --docker-server=<your-registry-server> \
     --docker-username=<user> \
     --docker-password=<pass> \
     --docker-email=<email>
   ```

2. **Reference in Pod Spec:**
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: private-pod
   spec:
     containers:
     - name: app
       image: my-priv-reg.io/app:v1
     imagePullSecrets:
     - name: my-registry-key
   ```

---

## 2. Image Vulnerability Scanning
Images should be scanned during the CI/CD pipeline before they ever reach the cluster.

* **Static Analysis:** Scanning the layers of an image for known CVEs (Common Vulnerabilities and Exposures).
* **Tools:** `Trivy`, `Clair`, or native scanners in AWS ECR/GCR.
* **DevOps Workflow:** A pipeline should fail if a "High" or "Critical" vulnerability is detected.



---

## 3. Admission Controllers: ImagePolicyWebhook
An **Admission Controller** is a piece of code that intercepts requests to the Kubernetes API server prior to persistence of the object.

* **ImagePolicyWebhook:** This specific controller can be configured to check with an external service (like a security scanner) to decide if an image is allowed to run.
* **Logic:** If the scanner says the image has a critical bug, the Admission Controller rejects the `kubectl apply` command.

---

## 4. Security Best Practices for Images

| Strategy | Action |
| :--- | :--- |
| **Specific Tags** | Never use `:latest`. Use specific versions or Shasums (e.g., `app:v1.2.3`). |
| **Minimal Base Images** | Use `distroless` or `Alpine` to reduce the attack surface (fewer binaries = fewer exploits). |
| **Read-Only Filesystem** | Set `readOnlyRootFilesystem: true` in the SecurityContext to prevent attackers from downloading tools. |
| **User Access** | Ensure the image does not run as the `root` user. |

---

## 5. CKA Exam Scenarios (Commands)
You might be asked to fix a pod that is failing to pull an image.

```bash
# 1. Identify the error
kubectl describe pod <pod-name>

# 2. Check for "ImagePullBackOff" or "ErrImagePull"
# Common causes:
# - Typo in the image name/tag.
# - Missing imagePullSecrets.
# - Network issues between Node and Registry.

# 3. Verify the secret exists
kubectl get secrets
```

---

### 💡 Practical Engineering Tip
In large organizations, we don't manually add `imagePullSecrets` to every Pod. Instead, we **patch the ServiceAccount**. If you add the secret to the ServiceAccount, every pod using that SA will automatically inherit the credentials.

```bash
# Automatically include the registry key for all pods using 'default' SA
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "my-registry-key"}]}'
```

---
