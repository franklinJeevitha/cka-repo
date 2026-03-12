
### 1. The "Move and Replace" Logic (Controller Manager & Scheduler)

The `kube-controller-manager` and `kube-scheduler` run as Static Pods. The Kubelet on that node constantly watches the directory `/etc/kubernetes/manifests/`.

* **`mv ... /tmp/`**: By moving the YAML file out of that directory, the Kubelet thinks the pod has been deleted. It will immediately stop and remove the running container.
* **`sleep 20`**: This gives the Kubelet enough time (the "polling interval") to realize the file is gone and successfully terminate the container processes.
* **`mv /tmp/ ... /etc/kubernetes/manifests/`**: By moving the file back, the Kubelet detects a "new" manifest. It will pull the image (if needed) and start a fresh container.

**When do you use this?**

* After you have manually edited the YAML files to change a setting (like a port or a timeout).
* If the component is "hung" or behaving strangely and needs a hard reset.

---

### 2. The "Systemd" Restart (Kubelet)

* **`systemctl restart kubelet`**: Unlike the other components, the Kubelet is **not** a container. It is a regular Linux service (a binary running on the OS).
* **What it does**: It stops the Kubelet process and starts it again. This forces it to re-read its configuration file (usually at `/var/lib/kubelet/config.yaml`) and re-scan the `/etc/kubernetes/manifests/` directory.

---


### Summary Table

| Component | Type | Restart Method |
| --- | --- | --- |
| **API Server** | Static Pod | Move manifest out/in of `/etc/kubernetes/manifests` |
| **Controller Manager** | Static Pod | Move manifest out/in of `/etc/kubernetes/manifests` |
| **Scheduler** | Static Pod | Move manifest out/in of `/etc/kubernetes/manifests` |
| **ETCD** | Static Pod | Move manifest out/in of `/etc/kubernetes/manifests` |
| **Kubelet** | OS Service | `systemctl restart kubelet` |
| **Kube-proxy** | DaemonSet | `kubectl delete pod -n kube-system -l k8s-app=kube-proxy` |

---

### ⚠️ Exam Tip

During the CKA, if you make a mistake in an `etcd.yaml` or `kube-apiserver.yaml` file, the pod will fail to start. You won't see it in `kubectl get pods` because the API server is down.

In that case, you **must** use host-level tools to see what went wrong:

1. **Check the container logs**: `crictl ps -a` (to find the exited container ID) and then `crictl logs <ID>`.
2. **Check system logs**: `journalctl -u kubelet -f`.
