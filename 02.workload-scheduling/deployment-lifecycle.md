1. Rolling Updates (Default Strategy)
Kubernetes updates pods in a rolling fashion, ensuring zero downtime by replacing old pods with new ones gradually.

How it works: It creates a new ReplicaSet and slowly shifts pods from the old one to the new one.

The Key Parameters:

maxSurge: How many pods can be created above the desired number during the update (e.g., 25% or 1).

maxUnavailable: How many pods can be "down" during the update process.

Command to Update Image:
kubectl set image deployment/<deploy-name> <container-name>=<new-image> --record

Note: The --record flag is deprecated in newer versions but still useful in labs to see the command in the rollout history.

2. Rollbacks (The Safety Net)
If a new deployment fails (e.g., the image doesn't exist or the app crashes), you must undo it.

Check Status: kubectl rollout status deployment/<name>

Check History: kubectl rollout history deployment/<name>

Undo to Previous: kubectl rollout undo deployment/<name>

Undo to Specific Revision: kubectl rollout undo deployment/<name> --to-revision=2

The Trigger: A Deployment only triggers a rollout if its Pod Template (spec.template) is changed (e.g., labels or image). Changing the number of replicas does not trigger a rollout.

Deployment vs. ReplicaSet: Always interact with the Deployment. Kubernetes manages the underlying ReplicaSets for you.

Checking Why a Rollout Stalled: If a rollout hangs, use kubectl describe deploy <name>. Look for ProgressDeadlineExceeded—this usually means the new pods are crashing.
