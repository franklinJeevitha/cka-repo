1. Multi-Container Design Patterns
In the KodeKloud labs, you are often asked to identify or build pods based on these three specific roles:

Sidecar: Extends the functionality of the main container (e.g., a logging agent like fluentd or logstash collecting logs from the application).

Ambassador: A proxy that handles external communication (e.g., connecting to a database at localhost:5432 which the Ambassador then routes to an external production DB).

Adapter: Standardizes/Transforms output (e.g., taking application metrics and converting them into a format for a monitoring tool).

2. Init Containers (The "Pre-Req" Container)
KodeKloud labs frequently use Init Containers to simulate "waiting" for a service.

Behavior: They must run to completion before the main container starts.

Lab Scenario: "Create a pod that waits for a service called myservice to be available before starting the main app."

🛠️ YAML Example (KodeKloud Style)
YAML
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c', "until nslookup myservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done"]
3. Shared Volumes in Multi-Container Pods
A common lab task involves a Sidecar reading logs from a Main Container.

Logic: Both containers must mount the same volume.

Key Fields: spec.volumes (defines the storage) and spec.containers[*].volumeMounts (points to the storage).

📝 Salient Points (KodeKloud Highlights)
Logging: If a pod has two containers (app and sidecar), the command kubectl logs <pod-name> will fail. You must use kubectl logs <pod-name> -c <container-name>.

Localhost Communication: All containers in a pod share the same network. If container A runs on port 80, container B can reach it at http://localhost:80.

Restart Policy: If an Init Container fails, the entire Pod is restarted (repeatedly) until the Init Container succeeds.

Order of Operations: Init containers run sequentially (one after another), while Main containers run concurrently (at the same time).

🛠️ Validation (Exam Checklist)
Use kubectl get po — Look at the READY column. It will show 1/1 for single pods, but 2/2 for multi-container pods once both are running.

Use kubectl describe pod <name> — Scroll to the Init Containers section to check exit codes.

Check logs for a specific container:

Bash
kubectl logs multi-container-pod -c sidecar-container
