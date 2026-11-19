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

Terraform manages the `external-secrets/postiz` Vault record. Fill `postiz_credentials` in the ignored `iac/vault/terraform.tfvars`, using the generation commands in `terraform.tfvars.example`, then review and apply the workspace plan. Generate each of the four required secrets once with `openssl rand -hex 32` and preserve them on later applies. Do not regenerate database passwords or the JWT secret when adding a social provider.

The optional `linkedin_client_id` and `linkedin_client_secret` inputs default to empty strings. The Vault record still contains both properties because the current ExternalSecret requests them. Empty values allow application bootstrap; they do not connect a LinkedIn account. Add the real values to the private tfvars and apply Terraform when connecting LinkedIn. Access and refresh tokens created after connection are application data stored in PostgreSQL.

If the Vault record already exists outside Terraform, copy its existing values into the private inputs and import it before planning:

```shell
terraform -chdir=iac/vault import vault_kv_secret_v2.postiz external-secrets/data/postiz
```

Terraform owns the complete record. Update the private inputs rather than editing its values in the Vault UI; subsequent applies reconcile the record with those inputs.

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

## Temporarily pause the application

For a capacity assessment, exclude the dedicated Flux group from its parent reconciliation, suspend it, and scale only the Postiz application to zero. The extra exclusion is necessary because the cluster entrypoint also manages the child Kustomization and can otherwise restore it from Git. Suspension leaves the existing resources in place; PostgreSQL, Redis, Temporal, and their data remain available. The Postiz interface and its application workers stop.

```shell
kubectl -n flux-system patch kustomization postiz --type=merge -p '{"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}},"spec":{"suspend":true}}'
kubectl -n postiz patch deployment postiz --type=merge -p '{"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}},"spec":{"replicas":0}}'
kubectl -n flux-system get kustomization postiz -o jsonpath='{.spec.suspend}{"\n"}'
kubectl -n postiz get deployment postiz
kubectl -n postiz get pods,pvc
```

Verify that suspension is `true`, desired replicas are zero, and the application pod has terminated before comparing host memory, swap activity, and I/O pressure with the pre-pause measurements. A request timeout does not establish whether a write was applied; read back the desired state when the API becomes responsive. If the workstation cannot reach the API, run the commands in the server SSH session with `sudo k3s kubectl` and a bounded `--request-timeout=15s`.

During the 2026-11-19 assessment, application replicas were confirmed at zero with Flux suspended. API requests and the Metrics API responded again. The node reported 3140 MiB of memory use (58%). A subsequent pod-metrics snapshot showed Prometheus at 501 MiB, Grafana at 404 MiB, PostgreSQL at 170 MiB, Temporal at 88 MiB, and Redis at 3 MiB. Monitoring components together accounted for approximately 1 GiB. The initial pause was then reversed by the parent reconciliation; excluding the child Kustomization and application Deployment from reconciliation was required to hold it. These are provisional snapshots during recovery, not measured steady-state requirements or proof of sufficient headroom to restart Postiz. After applying both exclusions, the application pod terminated, zero replicas and suspension were rechecked, and PostgreSQL, Redis, and Temporal were all Ready. A later node snapshot reported 3396 MiB (62%); recovery measurements varied as workloads and cached pages settled. Check host paging and I/O wait separately; the earlier overload also caused node and database health-check failures.

Keep the group suspended during assessment. Its manifests remain unchanged in Git, and Flux will restore the declared application replica when reconciliation resumes. Other resources in the suspended group also stop receiving Git updates, although their operators and running pods continue working. The temporary exclusions prevent Flux from updating or pruning those two objects until removed. See [Flux reconciliation controls](https://fluxcd.io/flux/components/kustomize/kustomizations/#suspending-and-resuming).

After agreeing on capacity or workload changes, resume and verify:

```shell
kubectl -n postiz annotate deployment/postiz kustomize.toolkit.fluxcd.io/reconcile-
kubectl -n flux-system annotate kustomization/postiz kustomize.toolkit.fluxcd.io/reconcile-
flux resume kustomization postiz -n flux-system
flux reconcile kustomization postiz -n flux-system
kubectl -n postiz rollout status deployment/postiz --timeout=180s
```

Do not remove the Flux group or delete PVCs to perform this temporary pause. The [K3s troubleshooting guide](../../setup/k3s.md#ubuntu-apparmor-signal-workaround) records the separate AppArmor incident and host pressure diagnostics.

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
