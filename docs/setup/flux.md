---
icon: lucide/git-pull-request
---

# Bootstrap Flux

Flux Operator installs and manages the Flux controllers. The FluxInstance then watches the repository and reconciles its cluster entrypoint. Installing the operator and creating the instance are bootstrap steps; ordinary workload changes go through Git afterward.

## Review the source before bootstrap

`gitops/clusters/lab/flux-system/flux-instance.yaml` currently watches `https://github.com/HYP3R00T/homelab.git`, branch `main`, path `gitops/clusters/lab`. For a fork, update that source to your own repository before applying it. Do not combine this bootstrap with a second Flux installation for the same namespace.

Follow the [official Flux Operator installation guide](https://fluxoperator.dev/docs/guides/install/) to install the operator in `flux-system`, selecting and recording the operator chart version you intend to use. This repository declares the FluxInstance but does not declare the initial operator Helm installation.

## Apply the instance

Once the operator and its CRDs are available, apply the checked-in instance from the repository root:

```shell
kubectl apply -f gitops/clusters/lab/flux-system/flux-instance.yaml
kubectl -n flux-system get fluxinstance flux
flux get sources git -A
flux get kustomizations -A
```

The operator creates the controllers and the repository synchronization resources. Confirm the Git source revision matches the intended branch. `apps`, `infrastructure`, and then `secrets` should reconcile. The store and monitoring can remain unready until Vault bootstrap and credential population are complete.

Do not manually apply the entire cluster directory to bypass a dependency failure. Inspect [reconciliation](../gitops/reconciliation.md) and the [rollout runbook](../runbooks/gitops-rollout.md) to find the waiting boundary.

The embedded [Flux UI](../infrastructure/flux.md#web-ui) becomes reachable through its core ingress after [local access](local-access.md) is configured. A feature-branch push does not deploy: Flux watches `main`.
