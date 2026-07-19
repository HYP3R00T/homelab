---
icon: lucide/calendar-clock
---

# Postiz

Postiz schedules and publishes social media posts. This installation is sized
for one user and runs the application with dedicated Redis and Temporal
processes in the `postiz` namespace.

## Current implementation

| Property | Value |
|---|---|
| Image | `ghcr.io/gitroomhq/postiz-app:v2.21.7` |
| Namespace | `postiz` |
| Service | `postiz:5000` |
| Local hostname | `postiz.homelab.internal` |
| Public hostname | `postiz.hyperoot.dev` through Cloudflared |
| Replicas | 1 |
| Upload storage | 20 GiB retained local volume |
| Redis storage | 1 GiB retained local volume |
| PostgreSQL storage | 10 GiB retained local volume |

The Postiz container uses local upload storage. Redis persists its append-only
log locally. CloudNativePG runs one PostgreSQL instance containing the `postiz`,
`temporal`, and `temporal_visibility` databases. Temporal uses PostgreSQL
visibility instead of a separate Elasticsearch deployment.

## Store the bootstrap secrets

The four ExternalSecret resources read properties from the `postiz` object in
the `external-secrets` Vault KV v2 mount. Store the values before applying the
Postiz overlay:

```shell
export POSTIZ_JWT_SECRET="$(openssl rand -hex 32)"
export POSTIZ_DATABASE_PASSWORD="$(openssl rand -hex 32)"
export POSTIZ_TEMPORAL_DATABASE_PASSWORD="$(openssl rand -hex 32)"
export POSTIZ_REDIS_PASSWORD="$(openssl rand -hex 32)"

vault kv put -mount=external-secrets postiz \
  jwt-secret="$POSTIZ_JWT_SECRET" \
  postiz-database-password="$POSTIZ_DATABASE_PASSWORD" \
  temporal-database-password="$POSTIZ_TEMPORAL_DATABASE_PASSWORD" \
  redis-password="$POSTIZ_REDIS_PASSWORD"

unset POSTIZ_JWT_SECRET POSTIZ_DATABASE_PASSWORD
unset POSTIZ_TEMPORAL_DATABASE_PASSWORD POSTIZ_REDIS_PASSWORD
```

External Secrets creates the application, Redis, and two
`kubernetes.io/basic-auth` database Secrets. The manifests contain only Vault
references and non-sensitive connection metadata.

Social provider credentials are optional and can be added later. Access and
refresh tokens created after OAuth authorization are stored by Postiz in
PostgreSQL as runtime application data rather than bootstrap values managed by
Vault.

## Registration

The owner account has been created and `DISABLE_REGISTRATION` is enabled. Use
`https://postiz.hyperoot.dev` for sign-in and OAuth provider callbacks. The
local hostname remains available for diagnostics, but the public HTTPS hostname
is the canonical application URL.

## Configure providers later

Each provider must be configured through environment variables before its
channel can be connected in the dashboard. LinkedIn uses the
`linkedin-client-id` and `linkedin-client-secret` properties from the Postiz
Vault object. External Secrets maps them to `LINKEDIN_CLIENT_ID` and
`LINKEDIN_CLIENT_SECRET` in the application container.

Configure the LinkedIn application with this production OAuth redirect URI:

```text
https://postiz.hyperoot.dev/integrations/social/linkedin
```

For a LinkedIn Page integration, use `/integrations/social/linkedin-page`
instead. Other provider variable names are listed in the Postiz configuration
reference.

## Verify the deployment

```shell
kubectl get externalsecret,secret --namespace postiz
kubectl get cluster,database --namespace postiz
kubectl get pod,pvc,service,ingress --namespace postiz
kubectl rollout status deployment/postiz-redis --namespace postiz
kubectl rollout status deployment/postiz-temporal --namespace postiz
kubectl rollout status deployment/postiz --namespace postiz
```

If Postiz starts before its dependencies are ready, Kubernetes restarts or
rechecks the affected containers while External Secrets, CloudNativePG, and
Temporal converge.

## Data lifecycle

Postiz uploads, Redis data, and PostgreSQL data use the `local-path`
StorageClass. They survive pod restarts and normal node reboots, but not an NVMe
failure or a Talos reinstall that repartitions the disk. PostgreSQL contains
OAuth tokens and should be treated as sensitive data.

## Repository locations

- Reusable workloads: `gitops/apps/base/postiz`
- Lab storage, databases, secrets, and ingress: `gitops/apps/lab/postiz`
- Activation: `gitops/apps/lab/kustomization.yaml`

## References

- [Postiz documentation](https://docs.postiz.com/)
- [Postiz Docker Compose reference](https://github.com/gitroomhq/postiz-docker-compose)
- [Postiz LinkedIn provider](https://docs.postiz.com/providers/linkedin)
