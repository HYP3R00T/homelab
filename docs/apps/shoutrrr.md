---
icon: lucide/calendar-clock
---

# Shoutrrr

[Shoutrrr](https://github.com/coollabsio/shoutrrr/tree/v1.5.8) is the social scheduling application in the cluster entrypoint. It runs the published `ghcr.io/coollabsio/shoutrrr:1.5.8` image in one container, with SQLite for data, queues, cache, and sessions. No Redis, Temporal, or separate PostgreSQL server is added. TryPost was an unapplied trial and has been removed. Postflare is excluded because the operator does not want metered Cloudflare dependencies.

LinkedIn, X, and Instagram are supported by this release; Instagram requires media and supports Reels. YouTube and Substack are not supported. Schedule Shorts separately in YouTube Studio. Provider credentials, permissions, API pricing, callbacks, and media reachability must be checked before relying on publishing; running the application does not grant platform access.

## Resource budget

The pod requests 100m CPU and 256 MiB RAM, with limits of one CPU and 768 MiB. Octane has one web worker, the queue has one worker, and PHP's per-process memory limit is 128 MiB. SSR, engagement fetching, analytics, messages, and usage tracking are disabled. The scheduler remains enabled for scheduled publishing. A local isolated smoke test used about 264 MiB at idle and passed SQLite migrations, `/up`, first-owner creation, and registration blocking. This is not a measurement from the K3s VM. The published image occupies about 2.7 GiB unpacked, so its first pull can take time even though idle RAM is lower. These are trial settings, not a guarantee that uploads or all publishing jobs fit; assess real usage before increasing concurrency or limits.

The upstream Supervisor configuration is kept under `gitops/apps/shoutrrr/configs` with only the web-worker count capped. The stock FrankenPHP binary carries a file capability which prevents execution with all capabilities dropped. The startup arguments make an ordinary copy in `/tmp/shoutrrr-bin` and put it first on PATH; the copy omits file capabilities. The application stays nonroot, with all capabilities dropped and privilege escalation disabled. No host AppArmor change is needed for this adaptation.

## Persistent storage

Separate claims retain `/var/www/html/storage` (5 GiB for media and application storage) and `/var/www/html/database/sqlite` (1 GiB for SQLite). Both use `local-path-retain` and disable Flux pruning; the namespace is also protected. K3s's local-path provisioner creates the backing folders, and the pod's filesystem group makes the mounts writable. Do not create paths manually on the server. One replica and a Recreate strategy avoid two application instances sharing SQLite during upgrades.

Back up both volumes and the stable APP_KEY. For a consistent file backup, stop the application before copying the SQLite directory, including any WAL files, and storage. Retain protects against normal volume reclamation, not node loss or K3s uninstall; see [storage recovery](../runbooks/storage-recovery.md).

## Private configuration

The ignored `iac/vault/terraform.tfvars` contains `shoutrrr_credentials`. The tracked example includes `openssl rand -base64 32` for generating APP_KEY and the LinkedIn developer portal for obtaining client credentials. Preserve the key across reinstalls; changing it can make stored tokens unreadable. Optional LinkedIn values can be empty initially.

Terraform writes `external-secrets/shoutrrr`; ESO maps that record to `shoutrrr-app`. Keep inputs, state, and plans private:

```shell
umask 077
terraform -chdir=iac/vault validate
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
```

For a workspace with the shared five bootstrap resources already managed, adding Shoutrrr should create only its credential record, with no changes or deletions. Review the actual plan before applying it. Flux's Shoutrrr group waits for `infrastructure` and `secret-store`; CNPG is not a dependency of this SQLite application.

## Access and first owner

Open `https://shoutrrr.hyperoot.dev` after the application and Cloudflared are Ready. Public DNS points to the tunnel; a hosts-file entry is not needed. The former LAN hostname redirects to the public HTTPS address. See [tunnel setup](../runbooks/cloudflared-tunnel.md). The upstream entrypoint creates missing storage folders and SQLite, runs migrations, and starts the web server, worker, and scheduler.

On a fresh database, create the owner locally before enabling the public tunnel. The first registration claims the instance Owner role. `INSTANCE_REGISTRATIONS_ENABLED=false` permits that first owner but blocks subsequent public registrations; invited users are still possible, so do not issue invitations for this single-user setup. No default owner password or mail service is configured. Upstream skips email verification with the log mailer, so registration does not require an email link. Account recovery and invitations would require a deliberate mail setup; the log mailer is not email delivery.

The LinkedIn callback is `https://shoutrrr.hyperoot.dev/accounts/callback/linkedin`. Register this exact HTTPS URI in the LinkedIn developer application before reconnecting. The original LAN HTTP callback successfully connected LinkedIn on 2026-11-19; that hostname is no longer the canonical application origin. Preserve APP_KEY so stored account tokens remain decryptable. Callback changes do not require regenerating client credentials.

Cloudflare terminates browser TLS and the connector forwards to the cluster-internal HTTP Service. Shoutrrr uses secure cookies, forces HTTPS URL generation, and trusts proxy headers from the current node's pod network `10.42.0.0/24`. If the pod network changes, update that trust range. The origin has no public LoadBalancer service, and the tunnel has only one published hostname.

## Instagram through Meta

Facebook and Instagram share one Meta developer app in Shoutrrr v1.5.8. This deployment maps `facebook_client_id` and `facebook_client_secret` from private Terraform inputs into Vault, then ESO creates `FACEBOOK_CLIENT_ID` and `FACEBOOK_CLIENT_SECRET` in `shoutrrr-app`. No extra container or database is required. Graph API version `v25.0` matches the pinned application's default.

### Prepare the Meta account

1. Use an Instagram professional account linked to a Facebook Page you manage. Shoutrrr discovers Instagram through that Page; a standalone personal Instagram account is insufficient for this connector.
2. Create a Meta app at [Meta for Developers](https://developers.facebook.com/apps/) and add Facebook Login, as described in [Shoutrrr's account connection guide](https://shoutrrr.com/docs/connecting-accounts#facebook--instagram).
3. Register the callback the application actually sends: `https://shoutrrr.hyperoot.dev/accounts/callback/meta`. Meta requires HTTPS for this flow. Register the public callback exactly, then start a fresh authorization from the public Shoutrrr address.
4. Copy the Meta App ID and App Secret into the existing `shoutrrr_credentials` block in the ignored `iac/vault/terraform.tfvars`. These values come from Meta; they are not randomly generated passwords. Preserve APP_KEY and the existing LinkedIn fields.

```hcl
facebook_client_id     = "your-meta-app-id"
facebook_client_secret = "your-meta-app-secret"
```

Keep the Meta app limited to your own developer/test accounts initially. Publishing for accounts outside that scope requires the applicable permissions, App Review, and Business Verification. The pinned connector requests Page and Instagram permissions; inspect Meta's consent screen before authorizing access. See [upstream configuration](https://github.com/coollabsio/shoutrrr/blob/v1.5.8/.env.example.prod) for the complete scope list.

### Apply and connect

Review and apply a Terraform plan after filling the private fields. This updates only the existing Shoutrrr Vault record; it does not create another record. After the GitOps configuration has reached the cluster, force ESO to refresh:

```shell
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
kubectl -n shoutrrr annotate externalsecret shoutrrr force-sync="$(date +%s)" --overwrite
kubectl -n shoutrrr get externalsecret shoutrrr -o 'custom-columns=NAME:.metadata.name,REFRESHED:.status.refreshTime,READY:.status.conditions[0].status'
```

Wait for a new refresh timestamp and a Ready condition before restarting. Environment variables and Laravel's cached configuration are loaded at startup:

```shell
kubectl -n shoutrrr rollout restart deployment/shoutrrr
kubectl -n shoutrrr rollout status deployment/shoutrrr --timeout=300s
```

Refresh **Accounts → Connect account → Facebook / Instagram**, authorize the Meta app, and select the Facebook Page with the linked Instagram account. Credentials being present makes the connection available; it does not complete account authorization automatically.

### Media delivery remains a separate requirement

The v1.5.8 [Instagram connector](https://github.com/coollabsio/shoutrrr/blob/v1.5.8/app/Services/Publishing/Connectors/InstagramConnector.php) publishes by passing `image_url` or `video_url` for Meta to retrieve. The public HTTPS origin lets generated media URLs use `shoutrrr.hyperoot.dev`. Meta must be able to fetch those URLs without an Access login, bot challenge, or other interactive gate. A successful account connection does not prove that a Reel has published.

Cloudflared exposes this application only; no object-storage service is added. Shoutrrr uses its own account login, with public registration disabled. Its signed media-serving routes must remain reachable to Meta. Verify a media URL and an intentionally scheduled post before relying on unattended publishing. Instagram requires media; text-only posts are not supported.

## MCP access from Codex

Shoutrrr exposes its built-in MCP endpoint at `https://shoutrrr.hyperoot.dev/mcp`; no separate MCP deployment is needed. Follow the [upstream MCP guide](https://shoutrrr.com/docs/mcp) for supported tools and authentication. OAuth consent binds access to the workspace you select.

For Codex desktop and CLI, add the endpoint:

```shell
codex mcp add shoutrrr --url https://shoutrrr.hyperoot.dev/mcp
```

Shoutrrr v1.5.8's Content Security Policy permits the HTTP loopback callback `http://localhost:8787`. Codex defaults to `127.0.0.1` with a random port, which the browser blocks after consent. Add the following to your private `~/.codex/config.toml` before login; the callback URL and listener port must agree. Keep Shoutrrr's CSP enabled.

```toml
[mcp_servers.shoutrrr.oauth]
callback_url = "http://localhost:8787/callback"
callback_port = 8787
```

```shell
codex mcp login shoutrrr --oauth-client-registration dcr
codex mcp list
```

Select your workspace and approve once. A second submission of an already-consumed approval can produce `Check the response_type parameter`; start a fresh login instead. The fixed callback completed OAuth successfully on 2026-11-19.

Codex desktop and CLI share the user configuration. If this chat was already open, start a new chat after connecting so it can discover the tools. See [Codex MCP configuration](https://developers.openai.com/codex/mcp). Set `default_tools_approval_mode = "prompt"` under `[mcp_servers.shoutrrr]` to request tool approvals. Connecting grants workspace access; publishing, scheduling, and deleting posts still require a deliberate user request.

The startup command generates Passport signing keys only when both key files are absent and checks that both are nonempty before starting the server. They persist under the storage claim as `oauth-private.key` and `oauth-public.key`; include them in private storage backups alongside APP_KEY and SQLite. Never publish or routinely regenerate them. A partial key pair requires investigation instead of automatic replacement.

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

Check `/up`, registration/login, a small media upload, and an approved scheduled post. Watch memory, CPU, restarts, queue delay, and node swapping during real use; an idle measurement cannot establish peak capacity. Homepage exposes the application card and current pod readings, without retaining metric history.
