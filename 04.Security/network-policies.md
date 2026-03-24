In the CKA exam and daily operations, **Network Policies** are the "Pod-level firewalls." By default, all pods in Kubernetes can talk to all other pods. Network Policies allow you to change that to a **Default Deny** posture.

# 🛰️ Network Policies (Network Segmentation)

Network Policies define how groups of pods are allowed to communicate with each other and other network endpoints. They are **Namespace-scoped** and rely on **Labels** to select pods.

## 1. Core Logic: The "Isolating" Effect
* **Default Behavior:** All Pod-to-Pod communication is allowed (Non-isolated).
* **Policy Applied:** Once a `NetworkPolicy` selects a pod, that pod becomes **Isolated**. Any traffic not explicitly allowed by the policy is dropped.
* **Requirements:** You must have a **CNI Plugin** that supports Network Policies (like Calico, Cilium, or Weave). *Note: Flannel does NOT support Network Policies.*

---

## 2. YAML Anatomy (The 4 Pillars)
A Network Policy uses four main sections to define traffic:

1.  **podSelector:** Which pods does this policy apply to?
2.  **policyTypes:** Is this for Incoming (`Ingress`), Outgoing (`Egress`), or both?
3.  **Ingress/Egress - From/To:** Who is allowed to talk to the selected pods?
4.  **Ports:** Which specific TCP/UDP ports are open?

### **Example: Allow DB Access only from the Backend**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: prod
spec:
  podSelector:
    matchLabels:
      role: database         # Targets pods with this label
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend      # Only pods with this label can enter
    ports:
    - protocol: TCP
      port: 5432             # Only on this specific port
```

---

## 3. Complex Selectors (Namespaces vs. Pods)
You can filter traffic in three ways:
* **podSelector:** Pods in the *same* namespace as the policy.
* **namespaceSelector:** All pods in a *different* namespace that has a specific label.
* **ipBlock:** External IP ranges (CIDR) outside the cluster.



---

## 4. The "Security Best Practice": Default Deny
Before creating specific "Allow" rules, it is common to apply a "Default Deny" to the entire namespace. This ensures that nothing talks to anything unless you explicitly permit it.

**Default Deny All Ingress:**
```yaml
spec:
  podSelector: {}            # {} means "Select ALL pods in this namespace"
  policyTypes:
  - Ingress                  # Only traffic coming IN is blocked; OUT is still open
```

---

## 5. Troubleshooting & Validation
Network Policies are notoriously difficult to debug because they fail silently (packets are just dropped).

```bash
# 1. List policies in a namespace
kubectl get netpol -n <namespace>

# 2. Describe the policy to check selectors
kubectl describe netpol <policy-name>

# 3. Test connectivity (Standard CKA Troubleshooting)
# Try to reach the DB pod from a pod that SHOULD be blocked
kubectl exec <blocked-pod> -- curl -m 2 <db-pod-ip>:5432
# Result should be: "Connection timed out"
```

---

## 💡 Practical Engineering Tips

* **Labels are everything:** If you have a typo in your label (e.g., `role: db` vs `role: database`), the policy will silently fail to protect your pods. Always verify labels with `kubectl get pods --show-labels`.
* **Egress for DNS:** If you create a "Default Deny Egress" policy, your pods will lose the ability to resolve domain names. You **must** explicitly allow Egress to the `kube-system` namespace on port 53 (UDP/TCP) for CoreDNS to work.

---
