In Kubernetes, **Helm** is often referred to as the "Package Manager for Kubernetes" (analogous to `apt` for Debian or `pip` for Python). It allows you to manage complex applications by defining them as **Charts**.

---

## 1. Why Use Helm?
As applications grow, managing raw YAML files becomes difficult. You end up with multiple versions of `deployment.yaml`, `service.yaml`, and `ingress.yaml` for different environments (Dev, QA, Prod).

Helm solves this by:
* **Templating:** Use a single set of YAML files with variables (e.g., `{{ .Values.replicaCount }}`).
* **Version Control:** Roll back to a previous version of an application with one command.
* **Reusability:** Share complex application stacks (like Monitoring or Databases) as a single package.

---

## 2. Key Concepts & Terminology

### **A. Chart**
A bundle of YAML templates and a `values.yaml` file. This is the "package" itself.

### **B. Release**
An actual instance of a Chart running in a cluster. You can install the same "Nginx" Chart three times; each one will be a separate "Release" with its own name.

### **C. Repository (Repo)**
A place where Charts are stored and shared (e.g., Artifact Hub).

---

## 3. The Helm Chart Structure
When you run `helm create mychart`, it generates a standard directory structure:

* **`Chart.yaml`**: Metadata about the chart (name, version, description).
* **`values.yaml`**: The default values for your templates. This is where users change configurations.
* **`charts/`**: A directory containing any charts that this chart depends on.
* **`templates/`**: The actual Kubernetes manifest files with template logic.
    * **`_helpers.tpl`**: A place to put partial templates and logic.



---

## 4. Basic Imperative Commands

### **Managing Repositories**
```bash
# Add a new repository (e.g., Bitnami for databases)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update your local list of available charts
helm repo update

# Search for a specific chart
helm search repo nginx
```

### **Installing and Managing Releases**
```bash
# Install a chart (Name the release 'my-web-server')
helm install my-web-server bitnami/nginx

# List all running releases
helm list

# Upgrade a release with a new configuration
helm upgrade my-web-server bitnami/nginx --set replicaCount=3

# Roll back to the previous version
helm rollback my-web-server 1

# Uninstall a release
helm uninstall my-web-server
```

---

## 5. How Templating Works
Helm uses the Go template engine. It takes the values from `values.yaml` and injects them into the files in the `templates/` folder.

**Example `values.yaml`:**
```yaml
imageTag: "1.21"
replicas: 2
```

**Example `templates/deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deploy
spec:
  replicas: {{ .Values.replicas }}
  template:
    spec:
      containers:
      - name: nginx
        image: "nginx:{{ .Values.imageTag }}"
```



---

## 6. Summary: The Helm Workflow

| Step | Command | Description |
| :--- | :--- | :--- |
| **Search** | `helm search` | Find the application you want to install. |
| **Customize** | `edit values.yaml` | Adjust settings like ports, storage, or replicas. |
| **Install** | `helm install` | Deploy the application to the cluster. |
| **Monitor** | `helm status` | Check the health of the release. |
| **Maintain** | `helm upgrade/rollback` | Update or revert changes. |

---
