---
icon: lucide/key-round
---

# External Secrets

External Secrets Operator (ESO) turns references to Vault values into Kubernetes Secrets. It installs no application accounts and does not choose password values. This repository keeps the references public while the operator supplies the actual values through Vault.

| Property | Configuration |
| --- | --- |
| Chart | `external-secrets` `0.20.3` |
| Deployment owner | Flux secrets group |
| Operator manifests | `gitops/infrastructure/external-secrets` |
| Store manifests | `gitops/infrastructure/secret-store` |
| Store name | `vault` ClusterSecretStore |
| Vault authentication | Kubernetes mount `kubernetes`, role `eso`, token audience `vault` |
| Kubernetes identity | ServiceAccount `external-secrets` in namespace `external-secrets` |
| Vault KV mount | `external-secrets` (v2) |

## Initial setup

The separate secret-store group waits for the operator, but it also needs an initialized, unsealed, and configured Vault. Follow [Vault bootstrap](../runbooks/vault-bootstrap.md). The service-account identity and audience must match the Terraform role; the controller requests a token for that identity.

Monitoring then synchronizes `grafana-admin` and `prometheus-basic-auth` before Flux installs the chart. Shoutrrr has a separate included group that waits for this store and reads its own Vault record. The disabled Cloudflared bundle retains its own credential reference; installing ESO does not activate that tunnel.

## Verify and diagnose

```shell
kubectl -n external-secrets get pods
kubectl get clustersecretstore vault
kubectl -n monitoring get externalsecrets
```

Running controllers are the first check; a Ready store confirms provider authentication, and Ready ExternalSecrets confirm delivery of each requested value. If the store fails, inspect `kubectl describe clustersecretstore vault`. If the store works but a secret fails, inspect that ExternalSecret's events for missing paths or properties.

See the [official Vault provider guide](https://external-secrets.io/latest/provider/hashicorp-vault/) for the provider model. The repository's [secrets flow](../architecture/secrets-flow.md) explains the division between Terraform, operator setup, and synchronization.
