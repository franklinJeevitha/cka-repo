
### 1. Upgrade the Control Plane Node

You start here because the **API Server** must be the most advanced component in the cluster.

#### Step 1: Upgrade `kubeadm` binary

This provides the new "logic" for the upgrade.

```bash
# Replace 1.30.x-00 with your target version
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.30.0-00
apt-mark hold kubeadm

```

#### Step 2: Plan and Apply the upgrade

This command upgrades the **Static Pods** (API Server, Controller Manager, Scheduler).

```bash
kubeadm upgrade plan      # Shows you the available versions and checks for issues
kubeadm upgrade apply v1.30.0

```

#### Step 3: Drain the Control Plane (Optional/Best Practice)

In a single-master setup, this is often skipped in the exam unless specified, but it's the safest way to upgrade the Kubelet.

```bash
kubectl drain controlplane --ignore-daemonsets

```

#### Step 4: Upgrade `kubelet` and `kubectl`

The Kubelet must now be brought up to match the API Server.

```bash
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00
apt-mark hold kubelet kubectl

# Restart the service to apply changes
systemctl daemon-reload
systemctl restart kubelet

```

#### Step 5: Uncordon the Control Plane

```bash
kubectl uncordon controlplane

```

---

### 2. Upgrade the Worker Nodes

Once the Control Plane is at the new version, you move to the workers one by one.

#### Step 1: Drain the Worker Node (From the Control Plane)

This moves the workloads to other nodes so the users don't face downtime.

```bash
kubectl drain worker-1 --ignore-daemonsets --force

```

#### Step 2: Upgrade `kubeadm` on the Worker

**SSH into the worker node** for the next steps.

```bash
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.30.0-00
apt-mark hold kubeadm

```

#### Step 3: Upgrade the Node configuration

Unlike the master (which uses `apply`), workers use the `node` command.

```bash
kubeadm upgrade node

```

#### Step 4: Upgrade `kubelet` and `kubectl` on the Worker

```bash
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00
apt-mark hold kubelet kubectl

systemctl daemon-reload
systemctl restart kubelet

```

#### Step 5: Uncordon the Worker (From the Control Plane)

**Exit the worker** and return to the control plane.

```bash
kubectl uncordon worker-1

```

---

### Why the order matters?

If you upgrade the **Kubelet** to v1.30 while the **API Server** is still at v1.29, the Kubelet may try to use features or fields that the older API Server doesn't understand. This leads to the Node showing a `NotReady` status.

### Component Summary Table

| Component | How it's upgraded | Key Flag |
| --- | --- | --- |
| **kubeadm** | `apt-get install` | `apt-mark unhold` first |
| **Control Plane** | `kubeadm upgrade apply` | Upgrades Static Pods |
| **Worker Node** | `kubeadm upgrade node` | Local config upgrade |
| **Kubelet** | `apt-get install` | `systemctl restart` required |
| **Kube-proxy** | Automatic | Updated by `kubeadm upgrade apply` |

---

### ⚠️ Exam Warning

If the upgrade command asks for a confirmation or a configuration file, **always** check the documentation. In the CKA, you are allowed to have one tab open for **kubernetes.io/docs**.
