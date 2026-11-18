# Flux CD

Flux Operator manages the Flux instance declared in `gitops/clusters/lab/flux-system/flux-instance.yaml`. It watches main in this repository and reconciles `gitops/clusters/lab`. Existing source, Kustomize, Helm, notification, image automation/reflection, and source-watcher controllers are retained.

## Web UI

The operator embeds Flux Status. The ingress in `gitops/infrastructure/core/flux-web-ingress.yaml` routes `http://flux.homelab.internal` to `flux-operator.flux-system` on its `http-web` port, 9080. It uses K3s Traefik; no additional controller, web deployment, or persistent UI volume is installed.

Access is kept simple on the LAN with the installed operator's default configuration. No SSO, external identity provider, or new write-action configuration is introduced. Keep this endpoint private and inspect available UI actions when upgrading the operator rather than assuming every version has the same behavior.

For temporary workstation access:

```shell
kubectl -n flux-system port-forward svc/flux-operator 9080:9080
```

Open `http://localhost:9080`. For hostname access, map `flux.homelab.internal` to `192.168.0.61` on the workstation. See [reconciliation](../gitops/reconciliation.md) for group ownership and readiness.
