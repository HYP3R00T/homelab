---
icon: lucide/calendar-clock
---

# Postiz

Postiz is retained but inactive; no active Flux group includes this bundle. It schedules and publishes social media posts when deliberately deployed. This installation is sized for one user and runs the application with dedicated Redis and Temporal processes in the `postiz` namespace.

For the complete reconciliation chain and a file-by-file explanation, see [Postiz architecture](architecture.md).

## Retained configuration

| Property | Value |
|---|---|
| Image | `ghcr.io/gitroomhq/postiz-app:v2.21.7` |
| Namespace | `postiz` |
| Service | `postiz:5000` |
| Local hostname | `postiz.homelab.internal` |
| Public hostname | `postiz.hyperoot.dev` through Cloudflared |
| Replicas | 1 |
| Upload storage | 20 GiB local claim (inactive) |
| Redis storage | 1 GiB local claim (inactive) |
| PostgreSQL storage | 10 GiB local claim (inactive) |

The Postiz container uses local upload storage. Redis persists its append-only log locally. CloudNativePG runs one PostgreSQL instance containing the `postiz`, `temporal`, and `temporal_visibility` databases. Temporal uses PostgreSQL visibility instead of a separate Elasticsearch deployment.

## Trial resource envelope

The inactive bundle has the following memory configuration. These are trial limits, not measured requirements or a claim that the full stack fits alongside every other workload.

| Component | Memory request | Memory limit |
| --- | --- | --- |
| Postiz | 512 MiB | 2 GiB |
| Temporal | 256 MiB | 512 MiB |
| PostgreSQL | 256 MiB | 512 MiB |
| Redis | 64 MiB | 256 MiB |
| **Total, excluding CNPG operator** | **1088 MiB** | **3.25 GiB** |

A limit is a ceiling, not a reservation or a way to reduce actual memory use automatically. Validate scheduled publishing, peaks, and restarts after any future activation and increase a component's limit if measurements justify it. The retained public URL and callback configuration must be reviewed for the intended access model before activation; they are not required by the current private setup.

## Store the bootstrap secrets

The four ExternalSecret resources read properties from the `postiz` object in the `external-secrets` Vault KV v2 mount. Store the values before applying the Postiz overlay:

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

External Secrets creates the application, Redis, and two `kubernetes.io/basic-auth` database Secrets. The manifests contain only Vault references and non-sensitive connection metadata.

Social provider credentials are optional and can be added later. Access and refresh tokens created after OAuth authorization are stored by Postiz in PostgreSQL as runtime application data rather than bootstrap values managed by Vault.

## Registration

The retained configuration has `DISABLE_REGISTRATION` enabled; this does not establish that an owner account exists on a future installation. Review account bootstrap before activation. Use `https://postiz.hyperoot.dev` for sign-in and OAuth provider callbacks. The local hostname remains available for diagnostics, but the public HTTPS hostname is the canonical application URL.

## Configure providers later

Each provider must be configured through environment variables before its channel can be connected in the dashboard. LinkedIn uses the `linkedin-client-id` and `linkedin-client-secret` properties from the Postiz Vault object. External Secrets maps them to `LINKEDIN_CLIENT_ID` and `LINKEDIN_CLIENT_SECRET` in the application container.

Configure the LinkedIn application with this production OAuth redirect URI:

```text
https://postiz.hyperoot.dev/integrations/social/linkedin
```

For a LinkedIn Page integration, use `/integrations/social/linkedin-page` instead. Other provider variable names are listed in the Postiz configuration reference.

## Verify the deployment

```shell
kubectl get externalsecret,secret --namespace postiz
kubectl get cluster,database --namespace postiz
kubectl get pod,pvc,service,ingress --namespace postiz
kubectl rollout status deployment/postiz-redis --namespace postiz
kubectl rollout status deployment/postiz-temporal --namespace postiz
kubectl rollout status deployment/postiz --namespace postiz
```

If Postiz starts before its dependencies are ready, Kubernetes restarts or rechecks the affected containers while External Secrets, CloudNativePG, and Temporal converge.

## Data lifecycle

Postiz uploads, Redis data, and PostgreSQL data use the `local-path` StorageClass. They survive pod restarts and normal node reboots, but do not provide a backup or protection from VM disk loss or K3s uninstall. PostgreSQL contains OAuth tokens and should be treated as sensitive data.

## Repository locations

- Reusable workloads: `gitops/apps/postiz`
- Lab storage, databases, secrets, and ingress: `gitops/apps/postiz`
- Activation: `gitops/apps/kustomization.yaml`

## References

- [Postiz documentation](https://docs.postiz.com/)
- [Postiz Docker Compose reference](https://github.com/gitroomhq/postiz-docker-compose)
- [Postiz LinkedIn provider](https://docs.postiz.com/providers/linkedin)
