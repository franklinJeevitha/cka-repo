1. The Core Mechanism: EncryptionConfiguration
To enable encryption, you must create a configuration file on the Control Plane and tell the kube-apiserver to use it.

2. The Configuration File
You must create a file (usually at /etc/kubernetes/enc/enc.yaml) with this structure:

YAML
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc: # This is the recommended provider
          keys:
            - name: key1
              secret: <32-byte-base64-encoded-string>
      - identity: {} # This is the "plain text" fallback
3. Key Steps to Implement (The CKA Workflow)
Generate a safe key: head -c 32 /dev/urandom | base64

Create the YAML: Place the key in the EncryptionConfiguration file.

Update Kube-APIServer: Edit the static pod manifest at /etc/kubernetes/manifests/kube-apiserver.yaml.

Add Flag: --encryption-provider-config=/etc/kubernetes/enc/enc.yaml

Add Volume Mounts: You must mount the host folder /etc/kubernetes/enc into the pod so the API server can see the file.

Wait for Restart: The API server will restart automatically.

📝 Salient "Gotchas" for your Notes
Order Matters: The first provider in the list is used to write data. Subsequent providers are used for reading.

The "Identity" Provider: Always keep identity: {} as the last provider. If you lose your encryption keys or mess up the config, this allows the API server to still read unencrypted data.

Existing Secrets: Enabling encryption does not automatically encrypt secrets already in etcd. You must "nudge" them by running:
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
This reads every secret and writes it back, triggering the encryption.

Performance: aescbc is the most common choice for performance and security balance.

🛠️ How to Verify (The "Proof")
To verify encryption is actually working, you bypass the API server and look directly at etcd.

Create a secret: kubectl create secret generic secret-test --from-literal=pass=12345

Search for it in etcd:

Bash
# You need the etcdctl tool and certificates to run this
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/secret-test | hexdump -C
Unencrypted: You will see the word secret-test and 12345 in the output.

Encrypted: You will see the name of your provider (e.g., k8s:enc:aescbc:v1:key1) followed by random gibberish.
