when you look at the **raw API structure** (how the API server actually organizes its endpoints), there are several other paths used for system health, discovery, and metadata.

If you were to `curl` the API server directly (e.g., `curl https://localhost:6443/ -k`), you would see these "system" paths alongside the resource groups.

---

### 1. The System & Discovery Paths

These are used by tools (like `kubectl` or monitoring systems) to understand the cluster's status rather than to manage application resources.

* **/version**:
* **Purpose:** Returns the Kubernetes version (GitVersion, GoVersion, Platform).
* **Usage:** `kubectl version` hits this endpoint.


* **/healthz, /livez, /readyz**:
* **Purpose:** Used to check if the API server itself is healthy, live, or ready to handle requests.
* **Usage:** Load balancers use these to determine if the Master node is up.


* **/metrics**:
* **Purpose:** Exposes internal performance data in Prometheus format (e.g., API request latency, etcd helper counts).
* **Usage:** Used by the **Metrics Server** or Prometheus to monitor cluster health.


* **/logs**:
* **Purpose:** Provides a way to view host-level logs (like `/var/log/`) through the API. (Usually requires high-level cluster-admin permissions).


* **/openapi/v2 (or v3)**:
* **Purpose:** This is where the API server stores its "Swagger" or OpenAPI documentation. It tells `kubectl` what fields are valid for a Pod or Service.



---

### 2. Authentication & Authorization Paths

These handle the "Login" and "Can I do this?" logic.

* **/auth**: This isn't a single "login" page (Kubernetes is stateless), but it includes sub-paths for authentication tokens.
* **TokenReviews (`authentication.k8s.io`)**: Used by external services to check if a bearer token is valid.
* **SubjectAccessReviews (`authorization.k8s.io`)**: This is how `kubectl auth can-i ...` works. It asks the API server: *"Can this user perform this action?"*

---

### 3. The Metrics Group (`metrics.k8s.io`)

This is a special group. It is **not** part of the core API server binary.

* **How it works:** It is provided by an **Aggregation Layer** (usually the **Metrics Server**).
* **Purpose:** It provides real-time resource usage data (CPU/Memory) for Nodes and Pods.
* **Usage:** Commands like `kubectl top nodes` or `kubectl top pods` fetch data from this group.
* *Note:* If you don't install the Metrics Server, this API group will not exist.



---

## 📝 Updated API Mapping for your Notes

| Path / Group | Purpose | Example Tool |
| --- | --- | --- |
| `/api/v1` | Core resources (Pods, Nodes). | `kubectl get pods` |
| `/apis/apps/v1` | Workload resources (Deployments). | `kubectl get deploy` |
| `/version` | Get K8s version info. | `kubectl version` |
| `/metrics` | Internal performance monitoring. | Prometheus |
| `metrics.k8s.io` | Pod/Node resource usage. | `kubectl top` |
| `authorization.k8s.io` | Checking permissions. | `kubectl auth can-i` |

---

### ⚠️ Exam Tip

You will rarely need to interact with `/version` or `/healthz` manually in the CKA exam. However, you **will** likely need to use `kubectl auth can-i` to verify if the RBAC you just created is actually working.
