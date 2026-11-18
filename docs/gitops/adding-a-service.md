# Adding a service

Choose apps for end-user applications or infrastructure for administrative and shared platform services. Put monitoring components under infrastructure/kube-prometheus-stack; a web interface alone does not make a platform service an end-user application. Create a service directory with individual resource files such as deployment.yaml, service.yaml, and ingress.yaml, plus kustomization.yaml to list them. Add Helm values only when the service needs them; do not introduce base/lab copies for a single environment.

Keep related resources together and separate resources that require a readiness boundary. For a Helm operator, wait for the release and CRDs before reconciling custom resources. For a credential-dependent application, wait for its ExternalSecrets rather than relying on pod crash loops. Use the existing groups where these constraints match; add a Flux group only for a real dependency or independent lifecycle.

Render the directory with `kubectl kustomize`, check namespace/name identity and pruning impact, and wire it into `gitops/clusters/lab`. A directory alone is not activation. Update its documentation and Homepage only when activation is intended. See [reconciliation](reconciliation.md) for the existing graph.
