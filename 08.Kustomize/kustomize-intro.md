**Kustomize** is a configuration management tool for Kubernetes that allows you to manage manifests without using templates. Unlike Helm, which uses a "template and replace" approach, Kustomize uses a **"layering"** approach called **Patching**.

It has been natively built into `kubectl` since version 1.14, meaning you don't necessarily need to install a separate binary to use it.

---

## 1. The Core Philosophy: "No Templates"
The biggest difference between Kustomize and Helm is the lack of `{{ .Values.name }}` tags.
* **Helm:** You write a generic template and "fill in the blanks" with values.
* **Kustomize:** You write a valid, plain Kubernetes YAML (the **Base**). Then, you define "overlays" that modify that YAML for specific environments (Dev, Prod, etc.).

---

## 2. Key Concepts & Terminology

### **A. Base**
The foundation. It contains the standard Kubernetes manifests (Deployments, Services, ConfigMaps) that are common across all environments.

### **B. Overlays**
Environment-specific layers (e.g., `overlays/production`). An overlay "points" to a base and specifies only the changes needed for that environment (like increasing replicas or changing an image tag).

### **C. kustomization.yaml**
The "control file." Every directory managed by Kustomize must have this file. It tells Kustomize which files to include and what transformations to apply.



---

## 3. Standard Directory Structure
A typical Kustomize project looks like this:

```text
deployment/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── development/
    │   ├── kustomization.yaml
    │   └── cpu-limit-patch.yaml
    └── production/
        ├── kustomization.yaml
        └── replicas-patch.yaml
```

---

## 4. Basic Features

### **Common Labels and Annotations**
You can automatically add labels to every resource in the directory via the `kustomization.yaml`:
```yaml
resources:
- deployment.yaml
commonLabels:
  app: my-web-app
  environment: prod
```

### **ConfigMap and Secret Generators**
Kustomize can create ConfigMaps directly from files, ensuring that the Pods automatically restart (roll out) when the file content changes by appending a hash to the name.
```yaml
configMapGenerator:
- name: app-config
  files:
  - config.properties
```

---

## 5. Basic Commands

Since Kustomize is part of `kubectl`, the commands are straightforward:

| Task | Command |
| :--- | :--- |
| **View rendered YAML** | `kubectl kustomize <directory>` |
| **Apply configuration** | `kubectl apply -k <directory>` |
| **Preview Overlay** | `kubectl kustomize overlays/production` |

---

## 6. Kustomize vs. Helm

| Feature | Helm | Kustomize |
| :--- | :--- | :--- |
| **Logic** | Templates (Go Templating) | Overlays and Patches |
| **File Type** | Custom `.tpl` files | Standard Kubernetes `.yaml` |
| **Learning Curve** | Higher (programming logic) | Lower (standard YAML) |
| **Installation** | Requires `helm` binary | Built into `kubectl` |

---
