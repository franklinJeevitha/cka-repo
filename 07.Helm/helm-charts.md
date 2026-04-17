A **Helm Chart** is a collection of files that describe a related set of Kubernetes resources. Think of it as a template for your application that can be packaged and versioned. Instead of managing individual YAML files, you manage the entire application as a single unit.

---

## 1. Chart Structure
When you create a chart using `helm create <chart-name>`, it generates a specific directory structure. Every file has a defined purpose:

```text
mychart/
├── Chart.yaml          # Metadata about the chart (Name, Version, AppVersion)
├── values.yaml         # Default configuration values for templates
├── charts/             # Directory for sub-charts (dependencies)
├── templates/          # Directory for YAML templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── _helpers.tpl    # Partial templates and helper logic
│   └── NOTES.txt       # Plain text that prints out after installation
└── .helmignore         # Files to ignore when packaging the chart
```



---

## 2. Key Metadata: `Chart.yaml`
This file defines the identity of the chart. It uses **Semantic Versioning (SemVer)**.

* **`apiVersion`**: The chart API version (v2 for Helm 3).
* **`name`**: Name of the chart.
* **`version`**: The version of the **package/templates** (e.g., `1.0.1`).
* **`appVersion`**: The version of the **actual application** (e.g., Nginx `1.21.0`).

---

## 3. Configuration: `values.yaml`
This is the most important file for end-users. It defines variables that are injected into the templates.

**Example `values.yaml`:**
```yaml
replicaCount: 3
image:
  repository: nginx
  tag: "1.21"
service:
  type: ClusterIP
  port: 80
```

Users can override these defaults during installation using:
`helm install my-release ./mychart --set replicaCount=5`

---

## 4. The Templates Directory
The `templates/` folder contains the actual Kubernetes manifests. These files use the **Go Template engine** syntax to pull data from `values.yaml`.

**Example `templates/service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
  selector:
    app: {{ .Chart.Name }}
```



---

## 5. Built-in Objects
In the example above, you see terms like `.Release` and `.Values`. These are built-in objects provided by Helm:

* **`.Values`**: Values passed into the chart from the `values.yaml` file or command line.
* **`.Release`**: Information about the current release (e.g., `.Release.Name`, `.Release.Namespace`).
* **`.Chart`**: Metadata defined in `Chart.yaml` (e.g., `.Chart.Version`).
* **`.Capabilities`**: Information about the Kubernetes cluster (e.g., K8s version).
* **`.Template`**: Information about the current template being executed.

---

## 6. Validating and Packaging
Before deploying, you should verify that your chart is syntactically correct and package it for distribution.

| Task | Command | Description |
| :--- | :--- | :--- |
| **Lint** | `helm lint ./mychart` | Checks for manifest errors and best practices. |
| **Dry Run** | `helm install --dry-run --debug ./mychart` | Renders templates to the console without installing. |
| **Package** | `helm package ./mychart` | Compresses the chart into a `.tgz` file for sharing. |

---
