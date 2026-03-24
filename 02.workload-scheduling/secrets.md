
# 🔐 Kubernetes Secrets

Secrets are used to store and manage sensitive information, such as passwords, OAuth tokens, and ssh keys. While they look like ConfigMaps, they are stored in Base64 encoding and handled differently by the nodes.

## 1. Creation Methods (Imperative)
Avoid manual Base64 encoding whenever possible. Let `kubectl` do the heavy lifting:

* **From Literal:**
    `kubectl create secret generic db-user --from-literal=username=admin --from-literal=password=P@ssw0rd`
* **From File:**
    `kubectl create secret generic ssh-key --from-file=id_rsa=~/.ssh/id_rsa`
* **Docker Registry (Specific Type):**
    `kubectl create secret docker-registry my-registry-key --docker-username=user --docker-password=pass --docker-email=email@example.com`

---

## 2. How to Consume Secrets
You can inject secrets into your pods in two primary ways:

### **A. As Environment Variables**
Best for simple application configurations.
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-user
      key: password
```

### **B. As a Volume (More Secure)**
When mounted as a volume, the secret is stored in **tmpfs (RAM)**. This means the sensitive data never touches the node's physical hard drive.



```yaml
spec:
  volumes:
  - name: secret-volume
    secret:
      secretName: db-user
  containers:
  - name: app-container
    image: nginx
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/secrets"
      readOnly: true
```

---

## 3. The "Base64" Manual Shuffle
If you are given an existing YAML and asked to add a secret manually, you must encode the value first.

* **To Encode:** `echo -n 'mypassword' | base64`
* **To Decode:** `echo -n 'bXlwYXNzd29yZA==' | base64 --decode`

> [!WARNING]
> **Common Exam Trap:** If you use `echo` without the **`-n`** flag, it adds a newline character (`\n`) to the end of your string. This will cause your password or API key to fail because the newline becomes part of the secret!

---

## 4. Key "Gotchas" & Best Practices

| Type | Purpose |
| :--- | :--- |
| **generic** | For keys, passwords, and files (most common). |
| **docker-registry** | Specifically for `imagePullSecrets`. |
| **tls** | For SSL certificates (requires `--cert` and `--key`). |

* **Secret vs. ConfigMap:** Secrets are for **Sensitive** data; ConfigMaps are for **General** configuration.
* **Encryption at Rest:** By default, Secrets are only Base64 encoded (not encrypted). To truly secure them, you must enable `EncryptionConfiguration` in the API Server.
* **Security Risk:** Environment variables can be seen via `kubectl describe pod`. Volumes are preferred for higher security as they are stored in memory.

---

## 5. Validation & Troubleshooting
```bash
# List all secrets
kubectl get secrets

# View encoded data
kubectl get secret db-user -o yaml

# The "Pro Way" to decode a specific key instantly
kubectl get secret db-user -o jsonpath='{.data.password}' | base64 --decode
```

---
