In the CKA, this is often a "pass/fail" task—if the restore fails, the cluster doesn't come back, and you lose the points for that question.

---

### 1. Understanding ETCD in the Cluster

ETCD is the cluster's distributed key-value store. It stores the **state** of every object (Pods, Secrets, ConfigMaps, etc.).

* **Static Pod:** It typically runs as a static pod on the control plane.
* **Manifest Path:** `/etc/kubernetes/manifests/etcd.yaml`
* **Data Directory:** Usually `/var/lib/etcd`

---

### 2. The Backup (Snapshot)

To take a backup, you must use `etcdctl`. Since ETCD is secured with TLS, you **must** provide the paths to the certificate files found in the ETCD manifest.

#### Step-by-Step Command:

```bash
# 1. Identify the certificate paths from /etc/kubernetes/manifests/etcd.yaml
# 2. Run the snapshot save command
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot-pre-upgrade.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

```

**Verification:**

```bash
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot-pre-upgrade.db --write-out=table

```

---

### 3. The Restore (The Critical Part)

The restore process involves creating a **new** data directory from the snapshot and then pointing the ETCD service to that new directory.

#### Step 1: Restore to a new directory

```bash
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot-pre-upgrade.db \
  --data-dir=/var/lib/etcd-from-backup

```

#### Step 2: Update the ETCD Manifest

You must tell the ETCD pod to use the new directory. Edit `/etc/kubernetes/manifests/etcd.yaml`:

1. Find the **volumes** section:
```yaml
- name: etcd-data
  hostPath:
    path: /var/lib/etcd-from-backup  # Update this from /var/lib/etcd
    type: DirectoryOrCreate

```


2. (Optional but recommended) Update the **initial-cluster-token** if you are restoring to a completely new cluster to avoid conflicts.

#### Step 3: Verify the Cluster

Wait about 1–2 minutes for the static pod to restart.

```bash
kubectl get nodes
kubectl get pods -A

```

---

## 📝 Salient "Gotchas" for the Exam

* **`ETCDCTL_API=3`**: This environment variable is mandatory. If you don't set it, the command defaults to API v2, which doesn't support snapshots.
* **Static Pod Restart**: If you edit the manifest and the API server doesn't come back, check the ETCD logs on the node: `docker ps` or `crictl ps` followed by `crictl logs <container-id>`.
* **Permissions**: Ensure the new data directory has the correct permissions (usually owned by root, but the ETCD container needs to read it).

---

### 🛠️ Summary Checklist for your Git Repo

| Action | Component | Command/File |
| --- | --- | --- |
| **Locate Certs** | Manifest | `/etc/kubernetes/manifests/etcd.yaml` |
| **Save** | `etcdctl` | `snapshot save <path>` |
| **Verify Save** | `etcdctl` | `snapshot status <path>` |
| **Restore** | `etcdctl` | `snapshot restore <path> --data-dir=<new-path>` |
| **Update Path** | Manifest | Change `hostPath` to `<new-path>` |

