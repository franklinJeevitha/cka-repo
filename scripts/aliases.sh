# CKA Shortcuts
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdes='kubectl describe'
export do="--dry-run=client -o yaml" # Use like: k run nginx --image=nginx $do
