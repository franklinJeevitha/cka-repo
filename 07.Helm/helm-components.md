To understand Helm's architecture, it is essential to distinguish between the client-side tools and the logical objects it creates within your cluster. Since Helm 3, the architecture has been simplified by removing the server-side component (Tiller), making it more secure and easier to manage.

---

## 1. The Three Logical Pillars
Helm operates on three fundamental concepts that work together to manage applications.

* **The Chart:** This is the "blueprint." It is a bundle of information necessary to create an instance of a Kubernetes application. It contains templates, default settings, and metadata.
* **The Repository:** This is the "store." It is a place where charts can be collected and shared. 
* **The Release:** This is the "instance." When a Chart is installed in a cluster, it becomes a Release. You can have multiple releases of the same chart (e.g., `dev-db` and `prod-db`) running in the same or different namespaces.



---

## 2. Core Technical Components

### **A. The Helm Client (`helm` binary)**
The client is a command-line tool for end-users. Its primary responsibilities include:
* Local chart development.
* Managing repositories.
* Interacting with the Helm library to send requests to the Kubernetes API server.
* Requesting the installation, upgrade, or rollback of charts.

### **B. The Helm Library (SDK)**
The library is the engine that does the actual work. It is bundled within the Helm client. 
* It combines a Chart and Values to build a valid Kubernetes manifest.
* It interacts directly with the **Kubernetes API Server** via `kubeconfig` to apply those manifests.
* It stores the installation history as **Secrets** (by default) within the cluster.

### **C. Release Secrets (Storage Backend)**
Helm 3 stores release information in **Secrets** within the same namespace as the release. 
* These secrets contain the history of every `helm upgrade`.
* This is how Helm "remembers" what was deployed previously, allowing for `helm rollback`.



---

## 3. Anatomy of a Helm Chart
A Chart is not just a folder; it is a specific directory structure.

| File/Folder | Purpose |
| :--- | :--- |
| `Chart.yaml` | **Metadata:** Contains the name, version (SemVer), and description of the chart. |
| `values.yaml` | **Configuration:** The default values for variables. These are overridden by users during installation. |
| `templates/` | **Manifests:** The YAML templates that, when combined with values, generate Kubernetes objects. |
| `charts/` | **Dependencies:** Contains other charts that this chart depends on to function. |
| `crds/` | **Custom Resources:** Used to define Custom Resource Definitions before the rest of the chart is processed. |

---

## 4. Helm Versioning Components
Helm uses **Semantic Versioning (SemVer)** and distinguishes between two different version numbers in `Chart.yaml`:

1.  **Version (`version`):** The version of the **Chart** itself (e.g., you updated the template logic).
2.  **App Version (`appVersion`):** The version of the **Application** inside the container (e.g., upgrading Nginx from `1.20` to `1.21`).

---

## 5. Summary Table: Component Interaction

| Component | Function | Location |
| :--- | :--- | :--- |
| **Helm CLI** | User interface for commands | Local Machine / CI/CD |
| **Chart** | Packaged templates and metadata | Local or Repository |
| **Values** | User-defined variables | `values.yaml` or `--set` flag |
| **Release State** | History and current config | K8s Secrets (in-cluster) |
| **K8s API Server** | Receives and executes manifests | Kubernetes Control Plane |

---
