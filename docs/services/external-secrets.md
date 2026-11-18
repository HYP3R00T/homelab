# External Secrets

External Secrets Operator is pinned at 0.20.3 in `gitops/infrastructure/external-secrets`. The secrets Flux group installs the Helm release. A separate secret-store group waits for the operators and reconciles `gitops/infrastructure/secret-store`.

The ClusterSecretStore named vault uses Vault Kubernetes auth at kubernetes, role eso, and the external-secrets KV v2 mount. Its explicit ServiceAccount reference is external-secrets in the external-secrets namespace, matching the Terraform role. The requested token and Terraform role both specify audience vault, required by newer Vault versions. The controller must be able to request a token for that account.

Monitoring's ExternalSecrets deliver grafana-admin and prometheus-basic-auth before the Helm release is installed. Cloudflared and Postiz retain their own definitions but remain inactive. ExternalSecret references are not authorization to create, rotate, or expose secret values.

```shell
kubectl get clustersecretstore vault
kubectl get externalsecrets -n monitoring
```

See [Vault bootstrap](../runbooks/vault-bootstrap.md) when authentication or required values have not yet been configured.
