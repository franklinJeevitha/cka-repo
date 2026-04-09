## 1. Creating the Ingress Controller (Imperative-ish)
The community standard for installing the NGINX Ingress Controller is via **Helm**. This is the closest to an "imperative" one-liner for a full installation.

```bash
# 1. Add the official repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 2. Install the controller into its own namespace
helm install my-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

If you are in a **CKA Exam environment**, you are usually asked to apply a specific manifest:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

---

## 2. Creating Ingress Resources (Imperative)
You can use `kubectl create ingress` to quickly define routing rules.

### **A. Single Service Ingress**
Expose a single service at a specific domain:
```bash
kubectl create ingress simple-ing \
  --rule="app.example.com/=app-svc:80"
```

### **B. Path-Based Routing (Multiple Paths)**
Map different URL paths to different services:
```bash
kubectl create ingress path-ing \
  --rule="example.com/video*=video-svc:80" \
  --rule="example.com/images*=image-svc:80"
```

### **C. Host-Based Routing (Virtual Hosts)**
Route based on the domain name:
```bash
kubectl create ingress host-ing \
  --rule="mail.example.com/*=mail-svc:80" \
  --rule="drive.example.com/*=drive-svc:80"
```

### **D. Creating with TLS (SSL)**
If you have a pre-existing secret containing your SSL certificate:
```bash
kubectl create ingress tls-ing \
  --rule="secure.example.com/*=web-svc:443" \
  --annotation nginx.ingress.kubernetes.io/ssl-redirect="true"
```

---

## 3. Generating YAML Templates (The "Dry Run")
Since Ingress often requires complex **Annotations** (like rewrite-target), a common pro-tip is to generate the base YAML and then edit it.

```bash
kubectl create ingress my-ing \
  --rule="app.com/v1*=v1-svc:80" \
  --dry-run=client -o yaml > ingress-template.yaml
```

---

## 4. Useful Management Commands

| Action | Command |
| :--- | :--- |
| **List Ingresses** | `kubectl get ingress` |
| **Check Rules/Status** | `kubectl describe ingress <name>` |
| **Edit live Ingress** | `kubectl edit ingress <name>` |
| **Delete Ingress** | `kubectl delete ingress <name>` |

---

### 💡 Practical Engineering Tip
In the CKA exam, they often test your ability to add **Annotations**. You can do this imperatively on an existing resource:
```bash
# Add a rewrite-target annotation to an existing ingress
kubectl annotate ingress my-ingress nginx.ingress.kubernetes.io/rewrite-target=/
```

