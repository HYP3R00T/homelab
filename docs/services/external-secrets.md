---
icon: lucide/key-round
---

# External Secrets

External Secrets Operator reads values from an external secret backend and creates ordinary Kubernetes `Secret` objects for workloads.

In this repository, it is configured to read from Vault through a `ClusterSecretStore`.

## Current implementation

| Property | Value |
|---|---|
| Status | Active |
| Helm chart | `external-secrets` `0.20.3` |
| Namespace | `external-secrets` |
| Store | ClusterSecretStore `vault` |
| Authentication | Vault Kubernetes auth, role `eso` |
| Current consumers | Cloudflared, Grafana, Prometheus, Postiz |

## What it depends on

- Vault, through `gitops/clusters/lab/infrastructure-configs.yaml`
- The Vault-backed store definition in `gitops/infrastructure/configs/lab/external-secrets/cluster-secret-store.yaml`

## What depends on it

- `cloudflared`, through `gitops/infrastructure/configs/lab/cloudflared/external-secret.yaml`
- Grafana and Prometheus, through `gitops/monitoring/controllers/lab/kube-prometheus-stack/`
- Postiz, through `gitops/apps/lab/postiz/`

## Where it is activated

- `gitops/clusters/lab/infrastructure-controllers.yaml`
- `gitops/clusters/lab/infrastructure-configs.yaml`
- `gitops/infrastructure/controllers/lab/external-secrets/kustomization.yaml`
- `gitops/infrastructure/controllers/base/external-secrets/`

## Vault integration

The repository already points External Secrets at Vault:

- Vault address: `vault.vault.svc.cluster.local:8200`
- secret path: `external-secrets`
- auth role: `eso`

The Terraform workspace under `iac/vault` creates the matching mount, auth
backend, policy, and role. Cloudflared reads the `credentials` property from
`cloudflared/tunnel`. Grafana reads its administrator username and password
from `monitoring/grafana`. Prometheus reads only the bcrypt `users` entry from
`monitoring/prometheus` for Traefik Basic Auth. Postiz reads its application,
database, and Redis credentials from `postiz`; optional provider credentials
can be added there later.

See [Secrets flow](../architecture/secrets-flow.md) for the cross-service data
path and [Bootstrap Vault](../runbooks/vault-bootstrap.md) for the setup
procedure.

The operator owns generated Kubernetes Secrets. Application manifests should
reference those Secrets rather than copying Vault values into Git.

After a Kubernetes reinstall, the `ClusterSecretStore` remains invalid until
Vault is updated with the new cluster CA and token-reviewer JWT. A secret value
can exist at the correct Vault path while its consuming pod remains pending if
this authentication layer is stale.
