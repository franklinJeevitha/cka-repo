
## 📂 ConfigMap Salient Points

### 1. Creation Methods (Imperative is Faster!)

In the exam, don't write the YAML from scratch. Use these:

* **From Literal:** `kubectl create cm my-config --from-literal=APP_COLOR=blue --from-literal=APP_MODE=prod`
* **From File:** `kubectl create cm app-conf --from-file=config.properties`
* **From Env-File:** `kubectl create cm web-cm --from-env-file=.env`

### 2. How to Consume ConfigMaps in a Pod

There are three main ways to use them, and you should have a sample for each:

#### A. As Environment Variables (Single Key)

Use this when you need a specific value for a specific variable.

```yaml
env:
  - name: PLAYER_INITIAL_LIVES
    valueFrom:
      configMapKeyRef:
        name: game-config
        key: initial_lives

```

#### B. As Environment Variables (Entire Map)

Use this to dump every key-value pair in the ConfigMap as environment variables.

```yaml
envFrom:
  - configMapRef:
      name: game-config

```

#### C. As a Volume (Files)

Each key in the ConfigMap becomes a filename, and the value becomes the file content.

```yaml
spec:
  volumes:
    - name: config-volume
      configMap:
        name: log-config
  containers:
    - name: test-container
      image: busybox
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config

```

---

## 📝 Salient "Gotchas" & Troubleshooting

* **Immutable ConfigMaps:** In newer K8s versions, you can set `immutable: true`. This prevents accidental updates and improves performance, but you'll have to delete and recreate the CM to change it.
* **Case Sensitivity:** Keys in a ConfigMap must be valid DNS subdomains (alphanumeric, dots, or dashes).
* **Updates (The Big One):** * If you mount a ConfigMap as a **Volume**, updates to the CM are eventually reflected inside the container (without a restart).
* If you use **Env variables**, the container **must be restarted** (e.g., `kubectl rollout restart deploy`) to pick up the new values.


* **Size Limit:** ConfigMaps are stored in `etcd`. The limit is **1MB**. If your config is bigger, you need to use a different storage solution.

---

## 🛠️ Validation Commands

* **View contents:** `kubectl describe cm <name>`
* **View raw data:** `kubectl get cm <name> -o yaml`
* **Check values inside a pod:** `kubectl exec <pod-name> -- env` or `ls /etc/config`
