---
icon: lucide/calendar-clock
---

# Postiz

Postiz schedules and publishes social posts. Its dedicated Flux group is included in the cluster entrypoint and waits for CloudNativePG and the Vault secret store. Homepage and Linkding use their independent group, so unfinished Postiz bootstrap does not block them.

| Property | Configuration |
| --- | --- |
| Image | `ghcr.io/gitroomhq/postiz-app:v2.21.7` |
| Namespace | `postiz` |
| Browser access | `http://postiz.homelab.internal` |
| Internal service | `postiz:5000` |
| Replicas | 1 |
| Upload storage | 20 GiB retained local claim |
| Redis storage | 1 GiB retained local claim |
| PostgreSQL storage | 10 GiB retained local volume |

The bundle contains Postiz, Redis, Temporal, and one CNPG-managed PostgreSQL instance. PostgreSQL hosts the `postiz`, `temporal`, and `temporal_visibility` databases; Temporal does not require a second database server or Elasticsearch here. See [Postiz architecture](architecture.md) for the resource layout.

## Bootstrap prerequisites

Complete [Vault bootstrap](../../runbooks/vault-bootstrap.md) first. The store must authenticate and read the `external-secrets` KV v2 mount. The four Postiz ExternalSecrets then create the application, Redis, and two database Secrets. A declared Flux group does not prove that these prerequisites have completed.

For a new installation, create the following Vault record once. If it already exists, preserve its passwords and properties rather than replacing them or rotating the JWT key unintentionally:

```shell
export POSTIZ_JWT_SECRET="$(openssl rand -hex 32)"
export POSTIZ_DATABASE_PASSWORD="$(openssl rand -hex 32)"
export POSTIZ_TEMPORAL_DATABASE_PASSWORD="$(openssl rand -hex 32)"
export POSTIZ_REDIS_PASSWORD="$(openssl rand -hex 32)"

vault kv put -mount=external-secrets postiz \
  jwt-secret="$POSTIZ_JWT_SECRET" \
  postiz-database-password="$POSTIZ_DATABASE_PASSWORD" \
  temporal-database-password="$POSTIZ_TEMPORAL_DATABASE_PASSWORD" \
  redis-password="$POSTIZ_REDIS_PASSWORD" \
  linkedin-client-id= \
  linkedin-client-secret=

unset POSTIZ_JWT_SECRET POSTIZ_DATABASE_PASSWORD
unset POSTIZ_TEMPORAL_DATABASE_PASSWORD POSTIZ_REDIS_PASSWORD
```

The LinkedIn properties must exist because the current ExternalSecret explicitly requests them. Empty values allow application bootstrap before provider configuration; they do not connect a LinkedIn account. Set the real provider credentials later with `vault kv patch`, preserving the existing passwords. Access and refresh tokens created after connection are application data stored in PostgreSQL.

## Access and first account

Add `postiz.homelab.internal` to the workstation's hosts mappings using [Local access](../../setup/local-access.md). This deployment uses a private HTTP endpoint and sets `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` consistently to that hostname. It does not require a public Cloudflared tunnel.

`NOT_SECURED=true` selects Postiz's HTTP-compatible session behavior for this LAN setup. Use a reviewed TLS configuration before public access; this setting is not an HTTPS deployment recommendation. Do not use the old public hostname as the login or callback URL for this configuration.

After the application is ready, open the UI and create the initial owner account. The pinned version's `DISABLE_REGISTRATION=true` permits registration while no organization exists and blocks subsequent registration. It does not create an account automatically. See the [pinned authentication implementation](https://github.com/gitroomhq/postiz-app/blob/v2.21.7/apps/backend/src/services/auth/auth.service.ts) and [session implementation](https://github.com/gitroomhq/postiz-app/blob/v2.21.7/apps/backend/src/api/routes/auth.controller.ts).

## Connect providers

Register the required developer application with each social platform and configure its credentials before connecting the channel. LinkedIn uses `linkedin-client-id` and `linkedin-client-secret` in the existing Vault record. Other providers need their own variables and secret references; those are not configured by enabling the Postiz deployment.

Use [the official LinkedIn guide](https://docs.postiz.com/providers/linkedin) and the callback URL required for your chosen access model. A private `.internal` hostname is not evidence that a provider accepts its redirect URI or can fetch uploaded media from it. Resolve provider-specific HTTPS, callback, and media-reachability requirements before relying on scheduled publishing. Do not enable a public tunnel merely to make the pod Ready.

## Resource envelope

These are trial limits, not measured requirements or a guarantee that all workloads fit simultaneously.

| Component | Memory request | Memory limit |
| --- | --- | --- |
| Postiz | 512 MiB | 2 GiB |
| Temporal | 256 MiB | 512 MiB |
| PostgreSQL | 256 MiB | 512 MiB |
| Redis | 64 MiB | 256 MiB |
| **Application stack** | **1088 MiB** | **3.25 GiB** |
| CNPG operator | 128 MiB | 256 MiB |

A memory limit is a ceiling, not a reservation or an automatic reduction of actual consumption. Measure idle use, publishing peaks, restarts, and the whole node alongside monitoring. Increase a component limit or revisit placement if measurements show it is needed.

## Verify

```shell
flux get kustomizations cnpg postiz
kubectl -n cnpg get helmrelease,pods
kubectl -n postiz get externalsecrets
kubectl -n postiz get cluster,database,pods,pvc,service,ingress
kubectl -n postiz rollout status deployment/postiz-redis
kubectl -n postiz rollout status deployment/postiz-temporal
kubectl -n postiz rollout status deployment/postiz
```

Expect the operator ready, four ExternalSecrets synchronized, databases ready, claims bound, and application deployments available. Containers can retry while the database and Temporal initialize. If the group waits for `secret-store`, finish Vault setup rather than bypassing that dependency. Verify sign-in, upload a test asset, and perform an authorized test publication after configuring a provider.

## Persistence

New uploads, Redis data, and PostgreSQL data use `local-path-retain`. The namespace and directly managed upload/Redis claims have Flux pruning protection. Retain preserves released PV data, but does not provide a backup or protect against VM disk loss or K3s uninstall. Back up the database, uploads, and recovery material separately. PostgreSQL contains sensitive OAuth data.

## Repository locations

- Workloads, databases, secrets, storage, and ingress: `gitops/apps/postiz`.
- Operator: `gitops/infrastructure/cnpg`.
- Activation and dependencies: `gitops/clusters/lab/cnpg.yaml` and `gitops/clusters/lab/postiz.yaml`.

See [Postiz documentation](https://docs.postiz.com/) for product behavior and [storage recovery](../../runbooks/storage-recovery.md) before changing persistent data.
