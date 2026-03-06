
### 1. OS Maintenance: Cordon and Drain

When you need to reboot a node or perform maintenance, you must ensure pods are safely moved.

* **`kubectl cordon <node>`**: Marks the node as unschedulable. New pods will not be placed there.
* **`kubectl drain <node>`**:
* Evicts all pods from the node.
* **Flag: `--ignore-daemonsets**`: Mandatory because DaemonSets are managed by a controller that will just recreate them if deleted.
* **Flag: `--force**`: Mandatory if there are pods not managed by a controller (standalone pods).
* **Flag: `--delete-emptydir-data**`: Mandatory if a pod uses local `emptyDir` storage, as that data will be lost.


* **`kubectl uncordon <node>`**: Allows new pods to be scheduled on the node again.

---

### 2. Cluster Upgrades (The `kubeadm` Workflow)

The CKA exam requires you to upgrade components in a specific order.

#### **A. Upgrade the Control Plane**

1. **Upgrade `kubeadm**`:
```bash
apt-get update && apt-get install -y kubeadm=1.x.x-00

```


2. **Plan and Apply**:
```bash
kubeadm upgrade plan
kubeadm upgrade apply v1.x.x

```


3. **Upgrade `kubelet` and `kubectl**`:
```bash
apt-get install -y kubelet=1.x.x-00 kubectl=1.x.x-00
systemctl daemon-reload && systemctl restart kubelet

```



#### **B. Upgrade Worker Nodes**

1. **From the Control Plane**: Drain the node.
```bash
kubectl drain worker-1 --ignore-daemonsets

```


2. **On the Worker Node**:
```bash
apt-get install -y kubeadm=1.x.x-00
kubeadm upgrade node
apt-get install -y kubelet=1.x.x-00 kubectl=1.x.x-00
systemctl daemon-reload && systemctl restart kubelet

```


3. **From the Control Plane**: Uncordon the node.
```bash
kubectl uncordon worker-1

```



---

## 📂 Path: `03-Cluster-Maintenance/etcd-backup-restore.md`

### 1. ETCD Backup

You must provide the certificates because `etcd` is secured with TLS.

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/snapshot-pre-upgrade.db

```

### 2. ETCD Restore

1. **Run Restore Command**: This creates a new data directory.
```bash
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot-pre-upgrade.db \
  --data-dir=/var/lib/etcd-new

```


2. **Update Manifest**: Edit `/etc/kubernetes/manifests/etcd.yaml`.
* Change the **hostPath** for the volume named `etcd-data` from `/var/lib/etcd` to `/var/lib/etcd-new`.


3. **Verify**: The API server will restart automatically. Run `kubectl get nodes` to ensure the cluster is responsive.

---

## 📝 Critical Exam Facts

* **Static Pods**: All control plane components (APIServer, Scheduler, Controller Manager, ETCD) are static pods. Their manifests are in `/etc/kubernetes/manifests`. Editing these files triggers an automatic restart.
* **Kubelet Configuration**: The Kubelet config is usually at `/var/lib/kubelet/config.yaml`.
* **Versions**: You can only upgrade one minor version at a time (e.g., 1.28 to 1.29). You cannot skip from 1.27 to 1.29.
