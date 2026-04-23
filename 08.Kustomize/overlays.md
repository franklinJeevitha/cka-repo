In Kustomize, **Overlays** are the environment-specific layers that sit on top of your **Base**. While the Base defines the "what" (the standard application), the Overlay defines the "where" (Dev, Staging, or Production).

An overlay is essentially a folder that contains a `kustomization.yaml` pointing back to a base and providing the specific changes (patches) for that context.

---

## 1. The Anatomy of an Overlay
An overlay folder typically contains:
1.  **`kustomization.yaml`**: The brain of the overlay. It pulls in the base and lists the patches to apply.
2.  **Patch Files**: Small YAML snippets (e.g., `replica-count.yaml`) or JSON files that contain only the differences.
3.  **Local Resources**: Any resources unique to that environment (e.g., a specific `Secret` or `ConfigMap` that only exists in Prod).



---

## 2. Linking an Overlay to a Base
The most critical part of an overlay is how it references its source. You use the `resources` field with a relative path to the base directory.

**Example: `overlays/production/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Points to the base directory
resources:
- ../../base

# Transformations for THIS environment
namePrefix: prod-
commonLabels:
  env: prod
  billing: finance-dept

# Patches for THIS environment
patches:
- path: prod-resources.yaml   # Increases CPU/RAM
- path: replica-scale.yaml    # Increases replicas to 10
```

---

## 3. Creating Multi-Level Overlays
Kustomize allows for "nested" overlays. This is useful for large organizations that have "Regional" settings and then "Environment" settings.

* **Base**: Vanilla app.
* **Regional Overlay (US-East)**: Adds US-specific logging endpoints.
* **Env Overlay (Prod)**: Points to the Regional Overlay and adds production-scale replicas.



---

## 4. Key Use Cases for Overlays

| Component | Base Configuration | Dev Overlay | Prod Overlay |
| :--- | :--- | :--- | :--- |
| **Replicas** | 1 | 1 | 5 (High Availability) |
| **Service Type** | ClusterIP | NodePort (for testing) | LoadBalancer |
| **Resources** | 128Mi RAM | 256Mi RAM | 2Gi RAM |
| **Images** | `app:latest` | `app:feature-branch` | `app:v1.2.0` (pinned) |
| **Namespace** | default | dev-ns | prod-ns |

---

## 5. Summary Table: Overlay Logic

| Feature | Description |
| :--- | :--- |
| **Inheritance** | Overlays inherit everything from the base. |
| **Isolation** | Changes in the `dev` overlay never affect the `prod` overlay. |
| **DRY** | You only write the `deployment.yaml` once (in the base). |
| **Immutability** | The base remains untouched; all variations are in the overlay. |

---

## 6. Execution Command
To see the final result of an overlay without applying it to the cluster:
```bash
kubectl kustomize overlays/production
```
To apply it directly:
```bash
kubectl apply -k overlays/production
```

---

### 💡 Technical Note: Name Resolution
When an overlay uses `namePrefix: prod-`, Kustomize is smart enough to update all references. If your `service.yaml` points to a selector named `my-app`, and the overlay changes the Deployment name to `prod-my-app`, Kustomize automatically updates the Service's selector to match. This prevents "broken links" between resources.
