When a Service fails, it usually manifests as a "Connection Refused," "Timeout," or "404 Not Found" error. Troubleshooting follows the path of traffic: from the **Service DNS** down to the **Pod Application**.


---

## 1. The Service Troubleshooting Flow
Follow this logical sequence to isolate where the communication is breaking down.


### **Step 1: Verify Pod Health and Labels**
A Service is just a "selector." If the Pods aren't healthy or the labels don't match, the Service has nowhere to send traffic.
*   **Check Pod Status:** `kubectl get pods -l app=my-app`
*   **Check Labels:** Ensure the `selector` in your Service YAML exactly matches the `labels` in your Pod template.

### **Step 2: Check Endpoints/EndpointSlices**
This is the most common point of failure. If the Service cannot find any healthy Pods, the Endpoints list will be empty.
*   **Command:** `kubectl get endpoints <service-name>`
*   **What to look for:** If you see `<none>` or an empty list, your selectors are wrong, or your Pods are failing **Readiness Probes**.

### **Step 3: Test Internal DNS Resolution**
Verify if the cluster's DNS (CoreDNS) is actually resolving the Service name.
*   **Action:** Run a temporary "debug" pod and try to resolve the name.
    ```bash
    kubectl run busybox --image=busybox -it --restart=Never -- nslookup <service-name>
    ```
*   **Result:** If this fails, the issue is with **CoreDNS**, not your specific Service.

### **Step 4: Test Internal Connectivity (IP & Port)**
Check if you can hit the Service IP and the Pod IP directly from within the cluster.
*   **Action:** From the same debug pod, try to `wget` or `curl` the Service ClusterIP.
    ```bash
    wget -qO- http://<service-cluster-ip>:<port>
    ```
*   **If Service IP fails but Pod IP works:** The issue is with **kube-proxy** or **NetworkPolicies**.

---

## 2. Common Service Issues Checklist

| Symptom | Check This | Command/Fix |
| :--- | :--- | :--- |
| **No Endpoints** | Readiness Probes | `kubectl describe pod` (Look for probe failures) |
| **Connection Refused** | Target Port | Ensure `targetPort` in Service matches `containerPort` in Pod. |
| **Timed Out** | NetworkPolicy | Check if an Egress/Ingress policy is blocking traffic. |
| **DNS Fails** | CoreDNS | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |



---

## 3. Advanced Tools for Network Debugging

### **A. Inspecting Kube-Proxy (IP Tables/IPVS)**
Kube-proxy is responsible for the actual routing logic on each node. If the rules aren't created, traffic won't move.
```bash
# Check if kube-proxy pods are healthy
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# View logs for routing errors
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

### **B. Connectivity Check with `ephemeral containers`**
If your application pod is stripped of tools like `curl` or `telnet`:
```bash
kubectl debug -it <pod-name> --image=nicolaka/netshoot --target=<container-name>
```
*Note: `netshoot` is a "Swiss Army knife" container for network troubleshooting.*

---

## 4. Summary Table: Service Types & Debugging Focus

| Service Type | Primary Debug Point |
| :--- | :--- |
| **ClusterIP** | Internal DNS and Selector matching. |
| **NodePort** | Firewall rules on the Node and Port range (30000-32767). |
| **LoadBalancer** | Cloud Provider Integration (check `kubectl describe svc`). |
| **ExternalName** | External DNS resolution and CNAME records. |

---

```
