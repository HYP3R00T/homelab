---
icon: lucide/calendar-clock
---

# Shoutrrr

[Shoutrrr](https://github.com/coollabsio/shoutrrr/tree/v1.5.8) is the social scheduling trial replacing Postiz in the cluster entrypoint. It runs the published `ghcr.io/coollabsio/shoutrrr:1.5.8` image in one container, with SQLite for data, queues, cache, and sessions. No Redis, Temporal, or separate PostgreSQL server is added. TryPost was an unapplied trial and has been removed. Postflare is excluded because the operator does not want metered Cloudflare dependencies.

LinkedIn, X, and Instagram are supported by this release; Instagram requires media and supports Reels. YouTube and Substack are not supported. Schedule Shorts separately in YouTube Studio. Provider credentials, permissions, API pricing, callbacks, and media reachability must be checked before relying on publishing; running the application does not grant platform access.

## Resource budget

The pod requests 100m CPU and 256 MiB RAM, with limits of one CPU and 768 MiB. Octane has one web worker, the queue has one worker, and PHP's per-process memory limit is 128 MiB. SSR, engagement fetching, analytics, messages, and usage tracking are disabled. The scheduler remains enabled for scheduled publishing. A local isolated smoke test used about 264 MiB at idle and passed SQLite migrations, `/up`, first-owner creation, and registration blocking. This is not a measurement from the K3s VM. The published image occupies about 2.7 GiB unpacked, so its first pull can take time even though idle RAM is lower. These are trial settings, not a guarantee that uploads or all publishing jobs fit; assess real usage before increasing concurrency or limits.

The upstream Supervisor configuration is kept under `gitops/apps/shoutrrr/configs` with only the web-worker count capped. The stock FrankenPHP binary carries a file capability which prevents execution with all capabilities dropped. The startup arguments make an ordinary copy in `/tmp/shoutrrr-bin` and put it first on PATH; the copy omits file capabilities. The application stays nonroot, with all capabilities dropped and privilege escalation disabled. No host AppArmor change is needed for this adaptation.

## Persistent storage

Separate claims retain `/var/www/html/storage` (5 GiB for media and application storage) and `/var/www/html/database/sqlite` (1 GiB for SQLite). Both use `local-path-retain` and disable Flux pruning; the namespace is also protected. K3s's local-path provisioner creates the backing folders, and the pod's filesystem group makes the mounts writable. Do not create paths manually on the server. One replica and a Recreate strategy avoid two application instances sharing SQLite during upgrades.

Back up both volumes and the stable APP_KEY. For a consistent file backup, stop the application before copying the SQLite directory, including any WAL files, and storage. Retain protects against normal volume reclamation, not node loss or K3s uninstall; see [storage recovery](../runbooks/storage-recovery.md).

## Private configuration

The ignored `iac/vault/terraform.tfvars` contains `shoutrrr_credentials`. The tracked example includes `openssl rand -base64 32` for generating APP_KEY and the LinkedIn developer portal for obtaining client credentials. Preserve the key across reinstalls; changing it can make stored tokens unreadable. Optional LinkedIn values can be empty initially.

Terraform writes `external-secrets/shoutrrr`; ESO maps that record to `shoutrrr-app`. Existing Postiz and monitoring records remain managed separately. Keep inputs, state, and plans private:

```shell
umask 077
terraform -chdir=iac/vault validate
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

For a workspace with the original eight resources already managed, adding Shoutrrr should create only its credential record, with no changes or deletions. Review the actual plan before applying it. Flux's Shoutrrr group waits for `infrastructure` and `secret-store`; CNPG is not a dependency of this SQLite application.

## Preserve and stop Postiz

A commented reference alone does not stop existing workloads. Preserve and suspend the old group, stop its application processes, and hibernate its CNPG database:

```shell
kubectl -n flux-system patch kustomization postiz --type=merge -p '{"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled","kustomize.toolkit.fluxcd.io/prune":"disabled"}},"spec":{"suspend":true,"deletionPolicy":"Orphan"}}'
kubectl -n postiz scale deployment/postiz deployment/postiz-redis deployment/postiz-temporal --replicas=0
kubectl -n postiz annotate cluster/postiz-postgres --overwrite cnpg.io/hibernation=on
kubectl -n postiz get pods,pvc
```

Postiz data, manifests, namespace, claims, and Vault record remain available. Its entrypoint reference stays commented out, and its Flux object is protected from pruning. This does not migrate posts or accounts. Restoring Postiz requires deliberately reversing hibernation, restoring its reference, removing reconciliation exclusions, and resuming its group.

## Access and first owner

Map `shoutrrr.homelab.internal` to the current K3s node address using the [local access guide](../setup/local-access.md). Open `http://shoutrrr.homelab.internal` after the pod is Ready. The upstream entrypoint creates missing storage folders and SQLite, runs migrations, and starts the web server, worker, and scheduler.

Register your account immediately on the trusted LAN. The first registration claims the instance Owner role. `INSTANCE_REGISTRATIONS_ENABLED=false` permits that first owner but blocks subsequent public registrations; invited users are still possible, so do not issue invitations for this single-user setup. No default owner password or mail service is configured. Upstream skips email verification with the log mailer, so registration does not require an email link. Account recovery and invitations would require a deliberate mail setup; the log mailer is not email delivery.

The LinkedIn callback is `http://shoutrrr.homelab.internal/accounts/callback/linkedin`. Register that exact URI in the developer application if LinkedIn accepts it; check HTTPS and provider rules before connecting. Reusing client credentials does not update the provider's callback allowlist. Some media publishing integrations need publicly reachable media URLs, which private LAN HTTP cannot supply. No tunnel or public exposure is enabled by this trial. See the [upstream production environment example](https://github.com/coollabsio/shoutrrr/blob/v1.5.8/.env.example.prod) for other provider settings.

## Verify rollout

Flux watches main, so a local manifest change alone does not deploy the application. For an explicit trial before merge, apply the Vault record first, then run `kubectl apply -k gitops/apps/shoutrrr`. That installs only this application's bundle; it does not add the Flux group yet. After merge, the root creates the Shoutrrr group and Flux adopts those same named resources. Do not leave the working-tree configuration unmerged as the long-term source of truth.

After merging and applying the Vault record:

```shell
flux reconcile kustomization flux-system --with-source
kubectl -n flux-system get kustomization shoutrrr
kubectl -n shoutrrr get externalsecrets,pods,pvc
kubectl -n shoutrrr rollout status deployment/shoutrrr --timeout=600s
kubectl -n shoutrrr top pods
kubectl top nodes
```

Check `/up`, registration/login, a small media upload, and an approved scheduled post. Watch memory, CPU, restarts, queue delay, and node swapping during real use; an idle measurement cannot establish peak capacity. Homepage exposes the application card and current pod readings, while Prometheus/Grafana provide history.
