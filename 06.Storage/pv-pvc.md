
# 🏗️ Persistent Volumes (PV) and Claims (PVC)

In Kubernetes, we don't just "mount a drive." We use an abstraction layer that allows applications to stay portable across different clouds (AWS, Azure, On-prem).

## 1. The Relationship: PV vs. PVC
* **Persistent Volume (PV):** The actual "Storage Disk" in the cluster. Created by an **Administrator**. It is a **Cluster-wide** resource (like a Node).
* **Persistent Volume Claim (PVC):** The "Request" for storage. Created by a **Developer**. It is a **Namespaced** resource.



---

## 2. The Binding Process
When a developer creates a PVC, Kubernetes looks for a PV that matches the request (Capacity, Access Mode, StorageClass). If a match is found, they are "Bound" together.

### **Access Modes**
| Mode | Short Name | Description |
| :--- | :--- | :--- |
| **ReadWriteOnce** | `RWO` | Can be mounted by a **single** node (Common for block storage like AWS EBS). |
| **ReadOnlyMany** | `ROX` | Can be mounted by **many** nodes as read-only. |
| **ReadWriteMany** | `RWX` | Can be mounted by **many** nodes for reading and writing (Requires NFS or Ceph). |

---

## 3. Reclaim Policies
What happens to the data on the PV after the PVC is deleted?
* **Retain:** The PV is kept. An admin must manually clean up the data.
* **Delete:** The underlying storage (e.g., the AWS EBS volume) is automatically deleted.
* **Recycle:** (Deprecated) Performs a basic `rm -rf /` on the data and makes the PV available again.

---

## 4. YAML Examples

### **The PV (Admin Side)**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-log-data
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: "/mnt/data" # Only for local testing; use CSI for cloud
```

### **The PVC (Developer Side)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: log-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi # Will match with the 5Gi PV above
```



---

## 5. Using the Claim in a Pod
The Pod doesn't talk to the PV directly; it talks to the **Claim**.

```yaml
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: "/var/log/nginx"
      name: my-storage
  volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: log-claim
```

---

## 💡 Practical Engineering Tips

* **Static vs. Dynamic Provisioning:** * **Static:** You manually create 10 PVs. (What we just did).
    * **Dynamic:** You use a **StorageClass**. When a user creates a PVC, Kubernetes automatically calls the AWS/GCP API to create a disk and a PV on the fly. 
* **The "Pending" PVC:** If your PVC is stuck in `Pending`, check the `kubectl describe pvc`. Common reasons:
    1.  No PV matches the capacity (e.g., PVC asks for 10Gi, but your biggest PV is 5Gi).
    2.  Access modes don't match.
    3.  StorageClass names don't match.
* **Selector Power:** You can use **Labels** on PVs and **Selectors** on PVCs to ensure a specific claim binds to a specific disk (e.g., SSD vs HDD).

---
