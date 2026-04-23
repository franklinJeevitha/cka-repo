**Generators** in Kustomize are used to create Kubernetes **ConfigMaps** and **Secrets** from source files, environment files, or literal values. Unlike standard YAML manifests, Kustomize-generated resources are "dynamic" and provide built-in versioning.

---

## 1. Why use Generators?
In standard Kubernetes, updating a ConfigMap doesn't automatically tell a Deployment to restart. This often leads to "stale configuration" where the Pod is running old settings.

**Kustomize Generators solve this by:**
* **Automatic Hash Suffixing:** Every time the content of a file changes, Kustomize appends a new unique hash to the name (e.g., `app-config-8f9h2g`).
* **Triggering Rollouts:** Since the Deployment's `configMapRef` points to the name, and the name changes when the content does, Kubernetes detects a change in the Deployment spec and triggers a **Rolling Update** automatically.



---

## 2. ConfigMap Generator
You can generate ConfigMaps from three different sources in your `kustomization.yaml`.

### **A. From Files**
Ideal for large configuration files like `nginx.conf` or `application.properties`.
```yaml
configMapGenerator:
- name: web-config
  files:
  - configs/nginx.conf
```

### **B. From Environment Files (`.env`)**
Reads key-value pairs from a file and converts them into ConfigMap data.
```yaml
configMapGenerator:
- name: app-env
  envs:
  - dev.env
```

### **C. From Literals**
Defining key-value pairs directly in the YAML.
```yaml
configMapGenerator:
- name: app-params
  literals:
  - LOG_LEVEL=debug
  - MAX_THREADS=10
```

---

## 3. Secret Generator
The `secretGenerator` works exactly like the ConfigMap generator but creates `Kind: Secret` objects.

**Note:** The source files should be kept secure. Kustomize handles the encoding to Base64, but it does **not** encrypt the files on your local disk.

```yaml
secretGenerator:
- name: db-creds
  files:
  - username.txt
  - password.txt
  type: Opaque
```

---

## 4. Generator Options
You can control how the generators behave using the `generatorOptions` field.

```yaml
generatorOptions:
  disableNameHash: false   # Set to true to stop appending hashes (not recommended)
  labels:                  # Add specific labels to all generated objects
    type: generated
  annotations:
    note: "Do not edit manually"
```

---

## 5. Summary Table: Generator Types

| Generator Type | Source | Best For... |
| :--- | :--- | :--- |
| **`files`** | Path to a file | Large config files (`.yaml`, `.xml`, `.conf`). |
| **`envs`** | `.env` file | List of simple key-value environment variables. |
| **`literals`** | Direct strings | Small, specific settings (e.g., `DEBUG=true`). |

---

## 6. Practical Use Case: Overlay Specific Configs
A common pattern is to have a base Deployment and use Generators in the overlays to provide different settings.

**`overlays/dev/kustomization.yaml`**
```yaml
resources:
- ../../base

configMapGenerator:
- name: app-config
  literals:
  - DB_HOST=localhost
  - CACHE_ENABLED=false
```

**`overlays/prod/kustomization.yaml`**
```yaml
resources:
- ../../base

configMapGenerator:
- name: app-config
  literals:
  - DB_HOST=db.production.svc
  - CACHE_ENABLED=true
```

---

### 💡 Technical Note: The "Reference" Logic
You do not need to worry about the hashes in your Deployment YAML. In your base `deployment.yaml`, you simply refer to the name `app-config`. When Kustomize builds the manifest, it finds the generated name (e.g., `app-config-abc123`) and automatically updates all `volumes` and `envFrom` references in your Deployment to match.



---
