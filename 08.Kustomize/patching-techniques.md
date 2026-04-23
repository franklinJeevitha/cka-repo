In Kustomize, **Patches** are used when you need to make surgical, specific changes to a base resource that global transformers (like `commonLabels`) cannot handle. This allows you to keep your base YAML clean while modifying specific fields—like CPU limits, replica counts, or environment variables—for different environments.

There are two primary ways to patch: **Strategic Merge Patching** and **JSON 6902 Patching**.

---

## 1. Strategic Merge Patch (SMP)
This is the most common and "Kubernetes-native" way to patch. You write a small snippet of YAML that looks exactly like the resource you are modifying. Kustomize matches the `apiVersion`, `kind`, and `name`, and then merges your changes.

### **Use Case**
* Changing the number of replicas.
* Updating resource `limits` and `requests`.
* Adding a sidecar container to an existing Deployment.

### **Example: Updating Replicas**
**Base `deployment.yaml`:** (3 replicas)
**Overlay `replica-patch.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 10 # This will override the base value
```

---

## 2. JSON 6902 Patching
Sometimes you need to modify a specific element in a list (like the second container in a pod) or delete a specific field. JSON patches are more precise and follow the RFC 6902 standard.

### **Use Case**
* Modifying a specific index in an array.
* Removing a specific argument or environment variable.
* Changing a field that doesn't exist in all resources.

### **Example: Changing a Port via JSON Patch**
```yaml
- op: replace
  path: /spec/ports/0/port
  value: 8080
```

---

## 3. How to Apply Patches in `kustomization.yaml`

You must register your patches in the overlay's control file.

```yaml
resources:
- ../../base

patches:
# Option 1: Strategic Merge (Path to a file)
- path: replica-patch.yaml

# Option 2: JSON 6902 (Targeting a specific resource)
- target:
    kind: Service
    name: my-service
  patch: |-
    - op: replace
      path: /spec/type
      value: LoadBalancer
```



---

## 4. Comparison of Patching Types

| Feature | Strategic Merge Patch | JSON 6902 Patch |
| :--- | :--- | :--- |
| **Readability** | High (looks like K8s YAML) | Low (uses `op`, `path`, `value`) |
| **Precision** | Merges based on keys/names | Targeted by exact path or index |
| **Primary Use** | Adding/Updating fields | Replacing/Removing/Indexing |
| **Matching** | Done via Metadata (Kind/Name) | Done via a `target` block |

---

## 5. Summary Table: Patching Use Cases

| Change Required | Recommended Method |
| :--- | :--- |
| Change Replicas from 2 to 5 | **Strategic Merge** (Simple overwrite) |
| Add an Env Var to a container | **Strategic Merge** (Appends to the list) |
| Change the 3rd container's image | **JSON 6902** (Index-based access) |
| Remove a specific Annotation | **JSON 6902** (`op: remove`) |

---

### 💡 Technical Note: The "Merge" Logic
Strategic Merge is "smart" about lists. If you patch a container list, Kustomize looks for the `name` of the container. If the name matches, it updates that container. If the name is new, it adds it as a sidecar. This prevents you from accidentally overwriting your entire container array when you only wanted to change one variable.



---
