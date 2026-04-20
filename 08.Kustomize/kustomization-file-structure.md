The `kustomization.yaml` file is the entry point for Kustomize. It acts as a manifest of manifests, telling the engine which resources to load and what transformations (patches, labels, name changes) to apply to them.

---                                                                                                                                                                                                                                                                                                                                                                                                                                     
## 1. Sample `kustomization.yaml`
Here is a comprehensive example showing a mix of resource loading, generators, and global transformations.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# 1. Resource Loading
resources:
- deployment.yaml
- service.yaml

# 2. Global Metadata (Applied to ALL resources)
namespace: dev-namespace
namePrefix: dev-
commonLabels:
  project: phoenix

# 3. Generators (Creates new objects)
configMapGenerator:
- name: app-settings
  files:
  - config.json

# 4. Image Transformations
images:
- name: nginx
  newName: my-custom-nginx
  newTag: 1.21.0

# 5. Patching (Environment specific changes)
patches:
- path: replica-patch.yaml
```

---

## 2. Key Fields Explained

### **A. Resources**
The `resources` list identifies the files or directories that Kustomize should include in its build.
* Can be local files: `deployment.yaml`
* Can be other directories (Bases): `../base`
* Can be remote URLs: `github.com/org/repo/base?ref=v1.0`

### **B. Generators (ConfigMap & Secret)**
Generators are more powerful than just importing a YAML file.
* **Hash Suffixing:** Kustomize automatically appends a hash of the file content to the name (e.g., `app-settings-f79hg8`). 
* **Automatic Rollout:** If the content of `config.json` changes, the name changes. This forces Kubernetes to trigger a rolling update of any Deployment referencing that ConfigMap.



### **C. Cross-Cutting Fields**
These fields allow you to modify multiple resources at once without touching the original YAML files:
* **`namespace`:** Forces all resources into a specific namespace.
* **`namePrefix` / `nameSuffix`:** Useful for preventing name collisions when deploying the same base multiple times in one cluster (e.g., adding `dev-` or `-v2`).
* **`commonLabels` / `commonAnnotations`:** Injects labels/annotations into every resource and every selector (ensuring Services still point to the correct Deployments).

### **D. Images**
This section allows you to swap out container images without diving into complex JSON patching. You specify the `name` (the original image in the base YAML) and provide the `newName` or `newTag` to replace it with.

---

## 3. The `kustomization.yaml` Execution Logic

When you run `kubectl apply -k .`, the engine follows this order:
1.  **Load:** Read all files listed in `resources`.
2.  **Generate:** Create ConfigMaps and Secrets from the `generators`.
3.  **Transform:** Apply global changes (namespace, prefix, labels).
4.  **Patch:** Overlay specific changes from the `patches` section.
5.  **Output:** Ship the final, flattened YAML to the API server.



---

## 4. Summary Table

| Field | Purpose | Example |
| :--- | :--- | :--- |
| **`resources`** | Source manifests | `[deployment.yaml, service.yaml]` |
| **`namePrefix`** | Appends text to names | `web-` -> `web-nginx` |
| **`commonLabels`** | Metadata for all objects | `env: production` |
| **`images`** | Update container tags | `nginx:latest` -> `nginx:1.21` |
| **`patches`** | Strategic Merge or JSON patch | `path: update-cpu.yaml` |

---
