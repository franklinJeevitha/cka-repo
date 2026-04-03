In a dynamic cluster where Pod IPs change constantly, **Kube DNS** (now implemented by **CoreDNS**) is the glue that allows microservices to find each other.

---

# 📖 Kube DNS & Fully Qualified Domain Names (FQDN)

In Kubernetes, every **Service** and **Pod** is assigned a DNS name. This allows you to hardcode a name like `db-service` in your application code instead of a volatile IP address.

## 1. What is an FQDN?
A **Fully Qualified Domain Name** is the complete, absolute address of a resource in the cluster. It follows a strict hierarchical structure.

### **The Structure:**
`<resource-name>.<namespace>.<type>.<cluster-domain>`

* **resource-name**: The name you gave your Service or Pod.
* **namespace**: The K8s namespace (e.g., `default`, `prod`).
* **type**: Usually `svc` for Services or `pod` for Pods.
* **cluster-domain**: Default is `cluster.local`.

---

## 2. Service DNS (The Most Common)
When you create a Service, CoreDNS creates an `A` record for its **ClusterIP**.



| Type | Format | Example |
| :--- | :--- | :--- |
| **Full FQDN** | `svc-name.ns.svc.cluster.local` | `mysql.db-ns.svc.cluster.local` |
| **Relative** | `svc-name.ns` | `mysql.db-ns` |
| **Short Name** | `svc-name` | `mysql` |

> [!IMPORTANT]  
> **Short names** only work if the calling Pod is in the **same namespace** as the Service. If they are in different namespaces, you must use at least `svc-name.ns`.

---

## 3. Pod DNS
By default, Pods are not easily reachable by a simple name because they are ephemeral. However, they still have an FQDN based on their IP address.

* **Format:** `ip-with-dashes.namespace.pod.cluster.local`
* **Example:** If a Pod has IP `10.244.1.5` in the `default` namespace:  
  `10-244-1-5.default.pod.cluster.local`



---

## 4. How the Pod "Knows" the DNS Server
The **Kubelet** injects DNS settings into every container. You can see this by inspecting a Pod's configuration file.

```bash
# Run this inside any Pod
cat /etc/resolv.conf
```

### **Sample Output Explained:**
```text
nameserver 10.96.0.10             # The ClusterIP of the CoreDNS Service
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

* **`nameserver`**: All DNS queries from this Pod go to this IP (CoreDNS).
* **`search`**: This is the "Magic." If you ping `mysql`, the OS will try `mysql.default.svc.cluster.local` first, then `mysql.svc.cluster.local`, and so on.
* **`ndots:5`**: This is a performance setting. If a name has fewer than 5 dots, the OS will try to append the `search` domains before trying it as an absolute name.

---

## 5. Troubleshooting DNS in the Cluster
If your application says "Could not resolve host," use these steps to diagnose the "Kube DNS" stack.

### **Step 1: Verify CoreDNS is Running**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### **Step 2: Test with a Debug Pod**
Spin up a temporary `busybox` or `dnsutils` pod to test resolution.
```bash
kubectl run dns-test --image=tutum/dnsutils --sleep 3600
kubectl exec -it dns-test -- nslookup kubernetes.default
```

### **Step 3: Check the Service Endpoints**
If DNS resolves but the connection fails, verify CoreDNS is actually connected to the API server:
```bash
kubectl get endpoints kube-dns -n kube-system
```

---

## 📊 Summary Comparison

| Resource | DNS Mapping | Address Stability |
| :--- | :--- | :--- |
| **Service** | `name -> ClusterIP` | **Permanent** (until SVC is deleted) |
| **Pod** | `ip-dots -> PodIP` | **Volatile** (changes on restart) |
| **Headless Service** | `name -> Multiple Pod IPs` | Used for StatefulSets (Direct Pod access) |

---

### 💡 Practical Engineering Tip
If you are running a **StatefulSet** (like a Database cluster), you use a **Headless Service** (one where `clusterIP: None`). In this case, DNS doesn't return one IP; it returns a list of all Pod IPs. This allows your app to choose exactly which DB replica to talk to.

**Now that you have the DNS and Service layers mastered, are you ready to explore "Ingress" (Layer 7) to see how to expose these services to the outside world?**
