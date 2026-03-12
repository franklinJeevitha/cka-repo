In Kubernetes, the **Certificates API** is the built-in system that allows you to automate the process of requesting, signing, and managing TLS certificates.

Instead of manually generating certificates on your local machine using OpenSSL and copying them to nodes, you can use the Kubernetes API to handle the "handshake" between a requester and a **Certificate Authority (CA)**.

---

### 1. Why do we need it?

Every component in Kubernetes (Kubelet, Scheduler, Proxy) communicates over **TLS**. If a new node joins the cluster, it needs a certificate signed by the Cluster CA to prove its identity. The Certificates API allows this to happen without the administrator having to share the private CA key files manually.

### 2. The Core Object: `CertificateSigningRequest` (CSR)

When a user or a service needs a certificate, they create a **CSR** object in Kubernetes.

### 3. The 4-Step Workflow

This is a frequent task in the CKA exam:

1. **Generate a Key and CSR (Locally):**
A user generates a private key and a standard `.csr` file using `openssl`.
2. **Create the Kubernetes CSR Object:**
The user wraps that `.csr` file into a Kubernetes YAML file (`kind: CertificateSigningRequest`).
* The `.csr` content must be **Base64 encoded**.


3. **Approval:**
An administrator (or an automated controller) must approve the request.
* Command: `kubectl certificate approve <name>`


4. **Retrieval:**
Once approved, Kubernetes signs the certificate. The user can then extract the signed certificate from the `status.certificate` field of the CSR object.

---

### 🛠️ Step-by-Step Example for your Notes

#### Step 1: Create the YAML (`myuser-csr.yaml`)

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser-request
spec:
  request: <Base64_Encoded_CSR_Here>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # 1 day
  usages:
  - client auth

```

#### Step 2: Apply and Approve

```bash
kubectl apply -f myuser-csr.yaml
kubectl get csr
kubectl certificate approve myuser-request

```

#### Step 3: Extract the Certificate

```bash
kubectl get csr myuser-request -o jsonpath='{.status.certificate}' | base64 --decode > myuser.crt

```

---

### 📝 Key Concepts & "Signer Names"

Kubernetes uses different **Signers** depending on what the certificate is for:

* `kubernetes.io/kube-apiserver-client`: For users or services talking to the API.
* `kubernetes.io/kubelet-serving`: For the API server talking to the Kubelets.
* `kubernetes.io/kube-apiserver-client-kubelet`: For Kubelets talking to the API.

---

### ⚠️ Exam Tip: The "Signer" Gotcha

In the CKA exam, if you are asked to create a CSR for a new user, make sure you use the correct `signerName`. If you leave it blank or use the wrong one, the certificate might be approved but never actually **signed** (it will stay in a `Pending` state).
