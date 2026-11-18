# Reconciliation

Flux watches main at `gitops/clusters/lab`. Its individual group files contain the Flux Kustomizations; the directory Kustomizations assemble ordinary manifests. These are different uses of the same term.

| Flux group | Path under gitops | Waits for |
| --- | --- | --- |
| apps | apps | Nothing outside the app bundle |
| infrastructure | infrastructure/core | Nothing |
| secrets | infrastructure/secrets | infrastructure; then both Helm releases must be Ready |
| secret-store | infrastructure/secret-store | secrets; store must be Ready |
| monitoring-secrets | infrastructure/kube-prometheus-stack/secrets | secret-store; ExternalSecrets must be Ready |
| monitoring | infrastructure/kube-prometheus-stack | infrastructure and monitoring-secrets; Helm release must be Ready |
| monitoring-monitors | infrastructure/kube-prometheus-stack/monitors | monitoring |

The store cannot be Ready until Vault is initialized, unsealed, and configured for Kubernetes authentication. The monitoring secrets cannot be Ready until their approved values exist in Vault. This is an expected bootstrap gate, not a reason to remove dependsOn or embed credentials in Git.

Inspect status with:

```shell
flux get kustomizations -A
flux get helmreleases -A
kubectl get clustersecretstore vault
kubectl get externalsecrets -n monitoring
```

Apps remain independent so secret failures do not hold up their reconciliation. Optional Cloudflared, CloudNativePG, and Postiz are not included. Future Postiz activation needs its own Flux group depending on its operator and secret store; do not add it directly to the independent apps root and make all apps wait for its bootstrap.

New groups start reconciling when this configuration reaches the watched branch. Use [the rollout runbook](../runbooks/gitops-rollout.md) and inspect readiness after each boundary. Removing a managed resource can prune it. Never remove a namespace or PVC as a substitute for rolling back configuration. Core retained storage and directly managed Vault storage have pruning protection; verify rendered ownership before any migration.
