In Kustomize, **Components** are a specialized resource type designed for **reusability across different overlays**. While an Overlay represents an environment (Dev vs. Prod), a Component represents a "feature" or "trait" (like "External Auth," "Logging," or "Database Proxy") that can be toggled on or off regardless of the environment.


---

## 1. Why use Components?
Without Components, if you have a "Prometheus Sidecar" that needs to be added to both `staging` and `production`, you would have to duplicate the patch in both overlay folders.

**Components solve this by:**
* **Defining a feature once:** You create a `components/prometheus` folder.
* **Plugging it in anywhere:** Any overlay can simply list that component to inherit its patches and resources.

---

## 2. Directory Structure with Components
A project using components adds a third top-level directory:

```text
my-app/
├── base/
├── components/
│   ├── log-sidecar/          # A reusable feature
│   │   ├── kustomization.yaml
│   │   └── patch.yaml
│   └── external-auth/        # Another reusable feature
│       └── kustomization.yaml
└── overlays/
    ├── dev/                  # Only uses the base
    └── prod/                 # Uses base + log-sidecar
```



---

## 3. Defining a Component
A component's `kustomization.yaml` looks slightly different. It uses `kind: Component` instead of the default `Kustomization`.

**Example: `components/log-sidecar/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

# A component can add new resources (like a ConfigMap for logging)
resources:
- logging-config.yaml

# A component can patch existing resources in the base
patches:
- target:
    kind: Deployment
    name: my-app
  path: add-sidecar.yaml
```

---

## 4. Using a Component in an Overlay
To activate the feature, you list it under a specific `components:` field in your overlay's `kustomization.yaml`.

**Example: `overlays/prod/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

# Activating the shared features
components:
- ../../components/log-sidecar
- ../../components/external-auth

patches:
- path: prod-scale-patch.yaml
```

---

## 5. Summary Table: Overlays vs. Components

| Feature | Overlay | Component |
| :--- | :--- | :--- |
| **Primary Goal** | Define an environment (Dev/Prod) | Define a reusable feature (Auth/Logs) |
| **Inheritance** | Inherits from a **Base** | Is inherited **by** an Overlay |
| **Logic Type** | Vertical (Standard hierarchy) | Horizontal (Plug-and-play) |
| **Kind** | `kind: Kustomization` | `kind: Component` |



---

## 6. Use Cases for Components

* **Monitoring:** Adding Prometheus or Datadog sidecars to specific services across multiple clusters.
* **Security:** Injecting an "OAuth Proxy" or "Vault Agent" into legacy applications.
* **Debugging:** A "Debug" component that turns on verbose logging and attaches a debugger port, used only when troubleshooting.

---

### 💡 Technical Note: The Order of Operations
Kustomize processes **Resources** first, then **Components**, and finally **Patches** defined in the local overlay. This means that if a Component adds a sidecar, you can still use a patch in your `prod` overlay to change the CPU limits of that specific sidecar.
