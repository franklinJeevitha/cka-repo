
# 🚀 Kubernetes Gateway API: The Evolution of Ingress

The **Gateway API** is the modern successor to the Ingress API. While Ingress was a single, limited resource, the Gateway API is a collection of resources (**GatewayClass**, **Gateway**, and **Routes**) designed for better scalability, multi-tenancy, and native feature support without the need for vendor-specific annotations.

## 1. Why the Shift? (Roles & Responsibility)
The primary innovation is the **separation of concerns**. In a senior IT environment, different roles manage different parts of the network infrastructure:

* **Infrastructure Provider:** Manages the `GatewayClass` (The "Model" of the Load Balancer).
* **Cluster Operator:** Manages the `Gateway` (The physical entry point/IP/Port).
* **Application Developer:** Manages the `HTTPRoutes` (The logic mapping URLs to Pods).



---

## 2. Core Resource Samples & Configuration

### **A. GatewayClass (The Template)**
Defines **what** is providing the networking (e.g., NGINX, Istio, or a Cloud Load Balancer).
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: external-nginx
spec:
  controllerName: k8s-gateway.nginx.org/nginx-gateway-controller
  description: "Public facing NGINX Gateway"
```

### **B. Gateway (The Entry Point)**
Defines **where** the traffic listens. This is where the physical IP and Ports (80, 443) are assigned.
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: infra-ns
spec:
  gatewayClassName: external-nginx    # References the Class above
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: All                    # Allows any namespace to attach routes
```

### **C. HTTPRoute (The Routing Logic)**
Defines **how** traffic reaches the Pods. It "plugs into" a Gateway using `parentRefs`.
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
  namespace: dev-team
spec:
  parentRefs:
  - name: prod-gateway               # Attaches to the Gateway in infra-ns
    namespace: infra-ns
  hostnames:
  - "api.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /v1
    backendRefs:
    - name: api-service-v1
      port: 8080
```

---

## 3. Advanced Features (Native vs. Ingress)
Unlike Ingress, these features are **standardized** and do not require annotations:

* **Traffic Splitting (Canary):** Natively support weights (e.g., 90% to `v1`, 10% to `v2`).
* **Header-based Routing:** Route based on HTTP headers (e.g., `User-Agent` or `Auth-Token`).
* **Cross-Namespace Routing:** A Gateway in an infrastructure namespace can safely accept routes from application namespaces.
* **Layer 4 Support:** Unlike Ingress (L7 only), Gateway API supports **TCPRoute** and **UDPRoute**.



---

## 4. Management & Troubleshooting

### **Imperative Commands**
Since the Gateway API is based on Custom Resource Definitions (CRDs), use these commands to verify the status of the "plumbing":

| Task | Command |
| :--- | :--- |
| **Check Gateway Status** | `kubectl get gateway -A` |
| **Verify IP Assignment** | `kubectl describe gateway <name> -n <ns>` |
| **Check Route Binding** | `kubectl get httproute -A` |
| **Validate Classes** | `kubectl get gatewayclasses` |
| **Check Provisioning IP** | `kubectl get gtw -A` |
| **List Available Classes** | `kubectl get gc` |
| **Check Route Status** | `kubectl describe httproute <name>` |
| **View Listeners** | `kubectl get gtw <name> -o jsonpath='{.spec.listeners}'` |
| **Identify Controllers** | `kubectl get gatewayclasses -o custom-columns=NAME:.metadata.name,CONTROLLER:.spec.controllerName` |

### **Key Status Indicators**
When running `kubectl describe`, look for these two conditions in the `Status` block:
1.  **Accepted:** The controller has acknowledged the configuration is valid.
2.  **Programmed:** The controller has successfully configured the underlying Load Balancer/Hardware.

---

## 5. Imperative Commands for Gateway API
In a fast-paced SRE environment or during the CKA exam, you can use these commands to quickly generate or manage Gateway resources without manual YAML drafting.

### **A. Creating a Gateway (Imperative)**
You can define the listener and the class directly from the CLI.
```bash
# Create a Gateway listening on Port 80 for HTTP
kubectl create gateway prod-gateway \
  --gatewayclass=external-nginx \
  --listener="http:80:HTTP" \
  --namespace=infra-ns
```

### **B. Creating an HTTPRoute (Imperative)**
You can map a hostname and a backend service in one line.
```bash
# Create a route that maps 'api.example.com' to 'api-service'
kubectl create httproute api-route \
  --parentref=prod-gateway \
  --hostname="api.example.com" \
  --backend=api-service:8080 \
  --namespace=dev-team
```

### **C. Generating Templates (Dry-Run)**
Since Gateway API resources are often complex, use the `--dry-run` flag to generate a base YAML that you can then pipe into a file for editing.
```bash
kubectl create httproute my-route \
  --parentref=prod-gateway \
  --hostname="app.com" \
  --backend=app-svc:80 \
  --dry-run=client -o yaml > route-template.yaml
```

---

### 💡 Why YAML is still "King" for Gateway API
Unlike the older Ingress API, a single `HTTPRoute` can have multiple `parentRefs` (connecting to multiple Gateways) and complex `matches` (headers, query params, methods). While the imperative commands above are great for the basics, you'll find that for **Traffic Splitting** or **Filters**, jumping into the YAML via `kubectl edit` is usually necessary to define the `weight` or `requestMirroring` fields.

**Since we've now covered the imperative side of Gateway API, are we ready to move on to Network Policies, or is there another networking component you want to deep-dive into?**
## 💡 Practical Engineering Tip
In a Production/SRE context, the **`allowedRoutes`** field is your first line of defense. By setting it to `from: Same` or using `selector` labels, you prevent a developer in a "Dev" namespace from accidentally or maliciously hijacking a hostname (like `billing.com`) on a Production Gateway.
