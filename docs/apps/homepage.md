# Homepage

Homepage is the owner's LAN dashboard, using image ghcr.io/gethomepage/homepage:v2.7.0. Its complete service directory lives in `gitops/apps/homepage`, including configuration under configs. A generated ConfigMap mounts each application configuration file; a content change updates the generated name and triggers a rollout. Logs are temporary.

## Resource visibility

The Kubernetes information widget shows cluster and node CPU/memory through K3s Metrics Server. The generic Resources widget was removed because its container readings can be mistaken for the VM's usage.

Service cards use explicit namespaces and podSelector values to show application CPU/memory. Linkding selects app=linkding; Homepage selects app.kubernetes.io/name=homepage. Flux Operator, Vault, Grafana, Prometheus, and K3s Traefik have matching selectors. HTTP site checks show endpoint availability separately from pod resource readings. The internal Prometheus check uses /-/ready; its browser ingress remains authenticated.

Grafana and Prometheus links are declared for the configured monitoring rollout; they can show unavailable until Vault credentials and monitoring are Ready. Postiz and Cloudflared are not advertised as running. The old standalone Traefik API widget was removed; Traefik's card shows pod stats without inventing a dashboard route.

Static card configuration is used with ingress discovery disabled to avoid duplicate or unexpected cards. Existing external AI links, bookmarks, weather, and clock remain. Grafana supplies history; Homepage supplies a quick current view.

## Configuration files

Kubernetes resources such as deployment.yaml, service.yaml, and ingress.yaml live directly under gitops/apps/homepage. Application settings, service cards, widgets, bookmarks, CSS, and JavaScript live under configs/. The Kustomization generates the ConfigMap from those files and mounts them into Homepage. There is no separate Docker Compose deployment or preview task.
