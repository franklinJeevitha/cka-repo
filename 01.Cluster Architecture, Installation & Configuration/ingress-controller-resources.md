While Services handle internal routing and port mapping, Ingress provides the logic for URL-based routing, SSL termination, and name-based virtual hosting.

---

# 🛣️ Ingress: Layer 7 Traffic Management

In Kubernetes, Ingress consists of two separate components that must both be present to function:
1.  **The Ingress Controller:** The "Engine" (e.g., NGINX, HAProxy, Traefik).
2.  **The Ingress Resource:** The "Rulebook" (The YAML file you write).

---

## 1. The Ingress Controller (The Engine)
Unlike the Kubelet or Kube-Proxy, an Ingress Controller is **not** started automatically with the cluster. You must install one as a Deployment or DaemonSet.

* **Role:** It acts as a reverse proxy. It watches the Kubernetes API for new Ingress Resources.
* **Mechanism:** When it detects a new resource, it updates its internal configuration (e.g., `nginx.conf`) to route traffic to the appropriate service.
* **Entry Point:** The Controller is typically exposed to the outside world via a `Service` of type `LoadBalancer` or `NodePort`.

---

## 2. The Ingress Resource (The Rules)
The Ingress Resource is the API object where you define how traffic should be routed based on the **HTTP Host** or **URL Path**.

### **A. Path-Based Routing**
Routes traffic based on the URL suffix (e.g., `/api` vs `/static`).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing-ingress
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /video
        pathType: Prefix
        backend:
          service:
            name: video-service
            port:
              number: 80
      - path: /images
        pathType: Prefix
        backend:
          service:
            name: image-service
            port:
              number: 80
```

### **B. Host-Based Routing (Virtual Hosting)**
Routes traffic based on the domain name used in the request (e.g., `app.com` vs `api.com`).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-routing-ingress
spec:
  rules:
  - host: mail.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mail-service
            port:
              number: 80
  - host: drive.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: drive-service
            port:
              number: 80
```

---

## 3. Critical Configuration Fields

### **Path Types**
* **`Prefix`**: Matches based on a URL path prefix split by `/`. (e.g., `/v1` matches `/v1/users`).
* **`Exact`**: Matches the URL path exactly.
* **`ImplementationSpecific`**: Matching logic is determined by the specific Controller (e.g., NGINX).

### **Ingress Class**
The `ingressClassName` field tells the cluster **which** controller should handle this resource. This is vital if you run multiple controllers (e.g., one for internal traffic and one for external).

---

## 4. Troubleshooting Ingress

| Symptom | Command / Action | What to check... |
| :--- | :--- | :--- |
| **Ingress has no IP** | `kubectl get ing` | Check the "ADDRESS" column. If blank, the Controller is not configured/running. |
| **404 Not Found** | `kubectl describe ing` | Check the "Rules" section. Does the path match your request? |
| **503 Service Unavailable** | `kubectl get ep` | Ensure the backend Service has active Endpoints (Pods). |
| **Controller errors** | `kubectl logs -n <ns> <controller-pod>` | Look for syntax errors in the generated config. |

---

## 5. Summary: Why Use Ingress?

* **Consolidation:** You only need **one** Cloud Load Balancer (expensive) to route to dozens of internal services.
* **SSL/TLS Termination:** You can manage SSL certificates in one place (at the Ingress) rather than in every single Pod.
* **Advanced Features:** Supports rate limiting, URL rewriting, and basic authentication via **Annotations**.

---

### 💡 Practical Engineering Tip
In the CKA exam, pay close attention to **Annotations**. Many tasks require you to use specific annotations like `nginx.ingress.kubernetes.io/rewrite-target: /` to ensure that when a user hits `/app1`, the traffic reaches the backend pod as `/` rather than `/app1` (which might cause a 404 on the application side).
