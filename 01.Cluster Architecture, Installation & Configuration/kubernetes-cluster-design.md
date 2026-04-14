

# 🏗️ Kubernetes Cluster Design & Architecture

Designing a Kubernetes cluster is a balance between **High Availability (HA)**, **Resource Efficiency**, and **Security**. This guide covers the critical decisions required to build a resilient production environment.

-----

## 1\. Control Plane & Etcd Topology 

The Control Plane is the "brain" of your cluster. Its stability determines the cluster's survival.

### **A. Stacked etcd (Standard HA)**

Each control plane node runs `kube-apiserver`, `scheduler`, `controller-manager`, and an `etcd` member.

  * **Suitability:** Small to medium clusters (under 100 nodes).
  * **Pros:** Easier setup and lower infrastructure cost.
  * **Cons:** Coupled failure risk. If a node fails, you lose both a manager and a data member.

### **B. External etcd (Enterprise Grade)**

Etcd is hosted on a separate, dedicated cluster.

  * **Suitability:** High-scale environments (500+ nodes) or highly regulated financial/healthcare sectors.
  * **Pros:** Maximum resilience. Decouples the state-store from the management layer.
  * **Cons:** Increased management overhead and double the server footprint.

-----

## 2\. Node Sizing: Vertical vs. Horizontal Scaling

| Strategy | Specs | Best For | Pros/Cons |
| :--- | :--- | :--- | :--- |
| **Horizontal (Small Nodes)** | 2–4 vCPU<br>8–16 GB RAM | Web Frontends, Microservices, Stateless APIs | **Pros:** Small blast radius, easier bin-packing.<br>**Cons:** Higher control plane overhead. |
| **Vertical (Large Nodes)** | 32–64 vCPU<br>128–256 GB RAM | ML Training, Big Data (Spark), Large JVM Apps | **Pros:** Efficiency for massive workloads.<br>**Cons:** Huge blast radius (one failure = 100s of dead pods). |

-----

## 3\. Memory & CPU Management

Unlike CPU, **Memory is non-compressible**. If a node runs out of RAM, the Linux Kernel triggers an **OOM (Out Of Memory) Killer** to protect the OS.

  * **System Reserved:** Always reserve resources for the Kubelet and OS using `--kube-reserved` and `--system-reserved`.
  * **Allocatable Formula:** $$Allocatable = Capacity - Reserved - EvictionThreshold$$
  * **Workload Specifics:**
      * **Java/Spring Boot:** Requires high **Requests** (JVM allocates heap on startup).
      * **Node.js/Python:** Needs strict **Limits** to catch memory leaks early.

-----

## 4\. Storage Architecture & Persistence

Storage design depends on the "statefulness" of the workload and the required IOPS.

### **A. Networked Block Storage (EBS, Ceph, Azure Disk)**

  * **Suitability:** Standard databases (Postgres, MySQL).
  * **Feature:** Data persists independently of the node; can be re-attached to new nodes.

### **B. Local Persistent Volumes (Local PV)**

  * **Suitability:** High-performance distributed systems (MongoDB, Cassandra, ElasticSearch).
  * **Feature:** Uses the node's **Local NVMe SSD**. Offers the lowest latency but requires application-level replication because if the node dies, the local data is lost.

### **C. Shared File Systems (NFS, EFS)**

  * **Suitability:** CMS systems or legacy apps requiring `ReadWriteMany` access.

-----

## 5\. Network Design (CIDR Management)

You must define three non-overlapping IP ranges before initialization:

1.  **Node CIDR:** Physical IP range for the servers.
2.  **Pod CIDR:** Virtual IPs for containers (e.g., `10.244.0.0/16`).
3.  **Service CIDR:** Virtual IPs for ClusterIPs (e.g., `10.96.0.0/12`).

-----

## 6\. Workload Isolation & Security

To prevent a "Noisy Neighbor" from taking down the cluster, use these tools:

  * **Taints & Tolerations:** Reserve high-performance nodes for specific apps (e.g., Taint a node as `GPU=true` so only ML pods can land there).
  * **Anti-Affinity:** Use `podAntiAffinity` to ensure replicas of the same service are spread across different nodes or Availability Zones (AZs).
  * **Resource Quotas:** Limit the total RAM/CPU a single Namespace (Team) can consume.

-----

## 📊 Summary Design Checklist

| Feature | Dev/Test | Production |
| :--- | :--- | :--- |
| **HA Nodes** | 1 Control Plane | 3 Control Planes (Multi-AZ) |
| **Disk Type** | Standard HDD/SSD | High-IOPS NVMe |
| **Multi-Tenancy** | Soft (Namespaces) | Hard (Separate Clusters/Nodes) |
| **Blast Radius** | Medium | Minimal (Small/Medium Nodes) |

-----

### 💡 Practical Tip

In high-traffic regions like **Singapore**, inter-AZ data transfer can become a hidden cost. When designing your cluster, use **Pod Topology Spread Constraints** to keep chatty services (like a Web App and its Cache) in the same zone while still ensuring a backup exists in another zone for disaster recovery.
