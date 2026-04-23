Transformers in Kustomize are used to perform widespread, automated changes across all your resources without you having to manually edit every single YAML file.

---

## 1. Common Transformers
Common transformers apply metadata changes to **every** resource loaded in the `kustomization.yaml`. This ensures consistency across a specific environment.

### **A. `namespace`**
* **Use Case:** Deploying the same application into different namespaces (e.g., `dev`, `staging`, `prod`) without changing the base YAML.
* **Sample:**
    ```yaml
    namespace: finance-app-dev
    ```

### **B. `namePrefix` and `nameSuffix`**
* **Use Case:** Running multiple instances of the same app in one namespace or identifying resources during a migration (e.g., adding `-v2`).
* **Sample:**
    ```yaml
    namePrefix: cluster-a-
    nameSuffix: -beta
    ```
    *Result:* A Deployment named `nginx` becomes `cluster-a-nginx-beta`.

### **C. `commonLabels`**
* **Use Case:** Essential for cost tracking, ownership, and ensuring Service selectors match Deployment labels automatically.
* **Sample:**
    ```yaml
    commonLabels:
      app: web-store
      owner: platform-team
    ```

### **D. `commonAnnotations`**
* **Use Case:** Adding non-identifying metadata, such as logs, documentation links, or integration settings for external tools (e.g., Datadog or Prometheus).
* **Sample:**
    ```yaml
    commonAnnotations:
      oncall-channel: "#alerts-finance"
    ```

---

## 2. Image Transformers
Image transformers allow you to change the container image name, tag, or digest without using complex patches. This is the standard way to handle CI/CD pipeline updates.

### **Use Cases**
1.  **Environment Specifics:** Using `nginx:debug` in Dev and `nginx:stable` in Prod.
2.  **CI/CD Injection:** A pipeline builds an image with a commit hash (e.g., `app:a1b2c3`) and needs to update the manifest on the fly.
3.  **Private Registry:** Swapping a public image (DockerHub) for a hardened internal image (JFrog/ACR).

### **Sample Configuration**
```yaml
images:
- name: nginx                # The image name used in the base YAML
  newName: internal-registry/my-nginx
  newTag: 1.25.1-alpine
- name: alpine
  digest: sha256:24f77590... # Forces the use of a specific immutable digest
```



---

## 3. Practical Example: Merging Both
This is how a typical `overlays/prod/kustomization.yaml` looks when using these transformers:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

# Common Transformers
namespace: production
namePrefix: prod-
commonLabels:
  tier: frontend
  managed-by: kustomize

# Image Transformer
images:
- name: my-app-image
  newName: 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app
  newTag: v2.4.5
```

---

## 4. Summary Table

| Transformer | Action | Scope |
| :--- | :--- | :--- |
| **`namespace`** | Sets the namespace for all objects. | Global |
| **`namePrefix`** | Prepends a string to resource names. | Global |
| **`commonLabels`** | Injects labels into metadata AND selectors. | Global |
| **`images`** | Replaces image name, tag, or digest. | Specific to Containers |

---

### 💡 Technical Note
The `commonLabels` transformer is "intelligent." Unlike a raw text search-and-replace, Kustomize understands the Kubernetes schema. It will update the `labels` in the metadata, but also the `matchLabels` in a Deployment and the `selector` in a Service, ensuring that the networking doesn't break after the transformation.
