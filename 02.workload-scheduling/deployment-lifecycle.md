
### 1. Rolling Updates (Default Strategy)

Kubernetes updates pods in a rolling fashion, ensuring zero downtime by replacing old pods with new ones gradually.

* **How it works:** It creates a new ReplicaSet and slowly shifts pods from the old one to the new one.
* **The Key Parameters:**
* **`maxSurge`**: How many pods can be created *above* the desired number during the update (e.g., `25%` or `1`).
* **`maxUnavailable`**: How many pods can be "down" during the update process.


* **Command to Update Image:**
`kubectl set image deployment/<deploy-name> <container-name>=<new-image> --record`
> **Note:** The `--record` flag is deprecated in newer versions but still useful in labs to see the command in the rollout history.



---

### 2. Rollbacks (The Safety Net)

If a new deployment fails (e.g., the image doesn't exist or the app crashes), you must undo it.

* **Check Status:** `kubectl rollout status deployment/<name>`
* **Check History:** `kubectl rollout history deployment/<name>`
* **Undo to Previous:** `kubectl rollout undo deployment/<name>`
* **Undo to Specific Revision:** `kubectl rollout undo deployment/<name> --to-revision=2`

---

### 3. Deployment Strategies Comparison

| Strategy | Description | Pros | Cons |
| --- | --- | --- | --- |
| **RollingUpdate** | Gradual replacement (Default). | **Zero Downtime**. | Multiple versions run at once. |
| **Recreate** | Kills all old pods first, then starts new ones. | No version mismatch. | **Downtime** during the switch. |
| **Blue/Green** | Two full environments; switch traffic (via Service). | Instant cutover, easy rollback. | Double the resource cost. |
| **Canary** | Deploy to a small subset of users first. | Low risk, real-world testing. | Complex traffic routing. |

---

### 📝 Salient "Gotchas" for your Notes

* **The Trigger:** A Deployment only triggers a rollout if its **Pod Template** (`spec.template`) is changed (e.g., labels or image). Changing the number of replicas does **not** trigger a rollout.
* **Deployment vs. ReplicaSet:** Always interact with the **Deployment**. Kubernetes manages the underlying ReplicaSets for you.
* **Checking Why a Rollout Stalled:** If a rollout hangs, use `kubectl describe deploy <name>`. Look for `ProgressDeadlineExceeded`—this usually means the new pods are crashing.

---

### 🛠️ Sample YAML Snippet

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0 # Ensures 100% availability during update

```
