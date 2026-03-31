In Kubernetes, **CoreDNS** is the standard, built-in cluster DNS service. It is a flexible, extensible DNS server that sits in your cluster and ensures that Pods can find Services (and other Pods) using easy-to-remember names instead of volatile IP addresses.

# 🏗️ CoreDNS in Kubernetes

CoreDNS is a "Cluster Add-on" that runs as a Deployment (usually 2 replicas) in the `kube-system` namespace. It listens for Kubernetes API events and automatically creates DNS records for every Service and Pod created.



## 1. How Pods Find CoreDNS
When a Pod is created, the **Kubelet** automatically populates the Pod's `/etc/resolv.conf` file with the Cluster IP of the `kube-dns` Service.

```bash
# Inside a Pod, check the DNS config:
cat /etc/resolv.conf

# Output:
# nameserver 10.96.0.10             <-- The IP of the CoreDNS Service
# search default.svc.cluster.local  <-- Search path for short names
```

---

## 2. DNS Naming Convention
Kubernetes uses a very specific "Full Name" (FQDN) format for resources:

### **For Services:**
`<service-name>.<namespace>.svc.cluster.local`
* **Example:** A service named `web-auth` in the `prod` namespace:
  `web-auth.prod.svc.cluster.local`

### **For Pods (Less Common):**
`<pod-ip-with-dashes>.<namespace>.pod.cluster.local`
* **Example:** A pod with IP `10.244.1.5` in `default`:
  `10-244-1-5.default.pod.cluster.local`

---

## 3. The Corefile (Configuration)
CoreDNS is configured via a **ConfigMap** called `coredns` in the `kube-system` namespace. It uses a "Chain of Plugins" to handle requests.

```bash
kubectl get configmap coredns -n kube-system -o yaml
```

**Key Plugins in the Corefile:**
* **kubernetes:** Connects to the K8s API to resolve Service/Pod names.
* **forward:** If a name isn't in the cluster (e.g., `google.com`), forward the request to the Node's DNS (usually `/etc/resolv.conf` of the host).
* **cache:** Stores results in memory for a specific TTL (Time to Live) to speed up repeat queries.
* **health:** Reports the health of CoreDNS on port 8080.



---

## 4. Troubleshooting CoreDNS
If your Pods cannot talk to each other by name, CoreDNS is likely the issue.

### **Step 1: Check the Pods and Service**
```bash
# Are the CoreDNS pods running?
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Is the Service active?
kubectl get svc -n kube-system -l k8s-app=kube-dns
```

### **Step 2: Check the Logs**
```bash
# Look for errors in the CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### **Step 3: Test Resolution from a "Debug" Pod**
```bash
# Spin up a temporary pod to test DNS
kubectl run busybox --image=busybox --restart=Never -it -- sh

# Inside the pod:
nslookup kubernetes.default
```

---

## 💡 Practical Engineering Tips

* **High Availability:** Always run at least 2 replicas of CoreDNS. If CoreDNS goes down, your entire application will fail because the microservices won't be able to find each other.
* **Custom Domains:** You can add custom DNS entries (like for an external database) directly into the CoreDNS ConfigMap using the `rewrite` or `hosts` plugins.
* **Performance:** If you see high latency in DNS lookups, check the `cache` plugin settings in the Corefile or consider using **NodeLocal DNSCache** to reduce the load on the central CoreDNS pods.

---
