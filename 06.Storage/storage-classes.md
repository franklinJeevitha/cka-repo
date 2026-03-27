
# ⚡ StorageClasses (Dynamic Provisioning)

A `StorageClass` provides a way for administrators to describe the "classes" of storage they offer (e.g., "fast-ssd" vs "slow-hdd"). It eliminates the need for an admin to pre-create Persistent Volumes.



## 1. How it Works (The Workflow)
1.  **Admin** creates a `StorageClass` defining the provisioner (e.g., AWS EBS, Azure Disk).
2.  **Developer** creates a `Persistent Volume Claim (PVC)` and identifies the `storageClassName`.
3.  **Kubernetes** automatically contacts the Cloud Provider, creates a real disk, and creates a **Persistent Volume (PV)** in the cluster.
4.  **Binding** happens automatically between the new PV and the PVC.

---

## 2. YAML Anatomy

### **The StorageClass (The Provisioner)**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/aws-ebs  # The "Driver" (CSI)
parameters:
  type: gp3                         # Specific to the cloud provider
  fsType: ext4
reclaimPolicy: Delete               # What happens to the disk when PVC is deleted
volumeBindingMode: WaitForFirstConsumer
```

### **The PVC (The Request)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: auto-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage    # Must match the SC name above
  resources:
    requests:
      storage: 10Gi
```

---

## 3. Critical Parameter: Volume Binding Mode
This is a common CKA exam "gotcha."

* **Immediate:** (Default) The PV is created as soon as the PVC is made. 
    * **Risk:** The disk might be created in `us-east-1a`, but your Pod gets scheduled in `us-east-1b`. The Pod will fail to start because it can't reach the disk.
* **WaitForFirstConsumer:** The PV is only created **after** a Pod is scheduled. 
    * **Benefit:** Kubernetes knows exactly which node (and zone) the Pod is on, so it creates the disk in the correct location. **This is the recommended 2026 standard.**



---

## 4. Default StorageClass
If a PVC does not specify a `storageClassName`, it will use the "Default" class if one is configured in the cluster.

```bash
# Check which StorageClass is the default
kubectl get sc

# The default one will have (default) next to its name
# Example: standard (default)   kubernetes.io/aws-ebs
```

---

## 💡 Practical Engineering Tips

* **Reclaim Policy:** Be careful! Most StorageClasses default to `reclaimPolicy: Delete`. If you delete your PVC, your production database disk is gone forever. If the data is critical, change this to `Retain`.
* **Standardizing Tiers:** In your DevOps career, you'll likely set up tiers like `gold` (SSD), `silver` (Standard), and `archive` (S3/Cold Storage). This allows developers to choose the cost/performance profile they need without knowing the underlying cloud details.
* **Exam Speed:** If the CKA exam asks you to create a PVC with a specific StorageClass, you don't need to create a PV. Just make sure the `storageClassName` in your PVC YAML matches the one in the cluster.

---
