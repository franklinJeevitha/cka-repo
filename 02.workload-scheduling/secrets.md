📂 Secret Salient Points
1. Creation Methods (Imperative)
Avoid manually encoding strings to Base64. Let kubectl do the heavy lifting:
From Literal: kubectl create secret generic db-user --from-literal=username=admin --from-literal=password=P@ssw0rd
From File: kubectl create secret generic ssh-key --from-file=id_rsa=~/.ssh/id_rsa
Docker Registry (Specific Type): kubectl create secret docker-registry my-registry-key --docker-username=user --docker-password=pass --docker-email=email@example.com

2. How to Consume Secrets
Exactly like ConfigMaps, but using the secret keywords:
A. As Environment Variables
YAML
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-user
        key: password


B. As a Volume (Most Secure)
When mounted as a volume, the secret is stored in tmpfs (RAM), meaning the sensitive data never touches the node's hard drive.
YAML
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



3. The "Base64" Manual Shuffle
Sometimes you'll be given an existing YAML and asked to add a secret manually. You must encode the value first.
To Encode: echo -n 'mypassword' | base64
To Decode: echo -n 'bXlwYXNzd29yZA==' | base64 --decode
[!WARNING]
Common Exam Trap: If you use echo without the -n flag, it adds a newline character (\n) to the end of your string. This will cause your password or API key to fail because the newline becomes part of the secret!

📝 Salient "Gotchas" for your Notes
Types of Secrets:
generic: For keys, passwords, files (most common).
docker-registry: For imagePullSecrets.
tls: For SSL certificates (requires --cert and --key).
Secret vs. ConfigMap: Secrets are for "Sensitive" data. ConfigMaps are for "Configuration" data.
Encryption at Rest: By default, Secrets are stored in plain text in etcd. To truly secure them, you must enable EncryptionConfiguration. (This is a common "Cluster Architecture" task).
Environment Variable Risks: Be aware that environment variables can be seen by anyone who can run kubectl describe pod or look at the process list inside the container. Volumes are generally preferred for higher security.

🛠️ Validation Commands
List Secrets: kubectl get secrets
View (Encoded): kubectl get secret db-user -o yaml
View (Decoded) - The Pro Way:
kubectl get secret db-user -o jsonpath='{.data.password}' | base64 --decode
