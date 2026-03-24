In Kubernetes, **Custom Resources (CR)** are the way you extend the Kubernetes API. While Kubernetes comes with built-in resources (like Pods, Deployments, and Services), Custom Resources allow you to define your own objects that behave exactly like the native ones.

---

# 🧩 Custom Resources (CR) & Custom Resource Definitions (CRD)

Custom Resources allow you to store and retrieve structured data in the Kubernetes API. To make a Custom Resource work, you first need to provide a **Custom Resource Definition (CRD)**—the "blueprint" that tells Kubernetes what your new object looks like.



## 1. CR vs. CRD: The Difference
* **CRD (The Blueprint):** This is a physical file you apply to the cluster to define a new `kind`. It specifies the name, group, version, and the validation schema (OpenAPI v3) for your resource.
* **CR (The Object):** This is an instance of the CRD. Once the CRD is installed, you can create a CR using `kubectl apply -f my-resource.yaml`.

---

## 2. Why use Custom Resources?
In a professional environment, we use CRs to manage "Domain Specific" logic. 
* **Example:** Instead of managing 10 separate YAMLs for a Database (StatefulSet, Service, ConfigMap, Secret), you create a `kind: Database`. 
* **Declarative Power:** You can use `kubectl get`, `kubectl describe`, and `kubectl delete` on your custom objects just like you do with Pods.

---

## 3. The Operator Pattern
A Custom Resource by itself is just a "static piece of data" in `etcd`. To make it **do** something, you need a **Custom Controller** (often called an **Operator**).

1.  **User** creates a Custom Resource (e.g., `kind: Backup`).
2.  **The Operator** (a pod running in the cluster) watches the API for new `Backup` objects.
3.  **The Operator** triggers a script to actually perform the backup.



---

## 4. Key Commands
```bash
# List all Custom Resource Definitions in the cluster
kubectl get crds

# View the details/schema of a specific CRD
kubectl describe crd <crd-name>

# List all instances of a custom resource (e.g., Cert-Manager certificates)
kubectl get certificates.cert-manager.io
```

---

## 5. YAML Example (A Simple CRD)
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.mytools.io
spec:
  group: mytools.io
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                databaseName:
                  type: string
                retentionDays:
                  type: integer
  scope: Namespaced
  names:
    plural: backups
    singular: backup
    kind: Backup
    shortNames:
    - bk
```

---

## 💡 Practical Engineering Tips

* **Finalizers:** Custom Resources often use "Finalizers." If you try to delete a CR and it stays in `Terminating` status forever, it’s usually because the Operator is waiting to finish a cleanup task (like deleting a cloud resource) before removing the entry from `etcd`.
* **API Evolution:** When building automation, CRDs allow you to create a "Cloud-Native" interface. For example, instead of a Jenkins job, you might create a `kind: Pipeline` resource that your custom controller executes.
* **Short Names:** Always define `shortNames` in your CRD (like `bk` for `backups`). It makes your terminal work much faster during troubleshooting.

---
