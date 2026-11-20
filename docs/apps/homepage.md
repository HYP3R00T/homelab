---
icon: lucide/layout-dashboard
---

# Homepage

Homepage is the personal entry point to the homelab: shortcuts to applications and administrative tools, endpoint checks, and current CPU/memory readings. It runs as a single deployment using `ghcr.io/gethomepage/homepage:v2.8.0` in the `homepage` namespace.

| Property | Configuration |
| --- | --- |
| Owner | Flux apps group |
| Activation | Included; widget credentials come from Vault |
| Browser access | `http://homepage.homelab.internal` |
| Manifests | `gitops/apps/homepage` |
| Application configuration | `gitops/apps/homepage/configs` |
| Persistent application data | None; configuration comes from Git and logs are temporary |

## Configuration

Configure [local hostname access](../setup/local-access.md), wait for the deployment, and open the dashboard. No application account-creation step is declared. Review the static cards, external links, weather location, and bookmarks in `configs/` for your own use rather than treating this personal layout as a universal default.

The Kustomization generates a ConfigMap from the individual settings, service, widget, bookmark, CSS, and JavaScript files. A content change updates the generated name and triggers a deployment rollout. Flux deploys these configuration files to K3s; the optional workstation preview below mounts the same files.

## Local Docker preview

Use the [official Docker workflow](https://gethomepage.dev/installation/docker/) to preview layout changes before committing them. From the repository root:

```shell
docker compose -f dev/homepage/compose.yaml up -d
```

Open `http://localhost:3030`. The preview uses the same `v2.8.0` image as K3s and mounts the files in `gitops/apps/homepage/configs` read-only. Edit those source files on the workstation, then refresh Homepage to see changes. If a setting remains cached, use Homepage's refresh control. Editors that replace files atomically can leave individual bind mounts pointing to the previous file; recreate the preview to pick up those edits:

```shell
docker compose -f dev/homepage/compose.yaml up -d --force-recreate
```

The preview binds only to loopback and has no Docker socket or Kubernetes credentials. Every application config file is shared directly with GitOps; there are no preview copies or overrides. The shared Kubernetes configuration expects an in-cluster service account, so pod and node readings are unavailable in this standalone Docker container. Existing site checks use cluster-internal service names, so their indicators can report errors locally even when the cluster is healthy. Treat this as a visual preview and verify live metrics and endpoint checks in K3s. Browser links to LAN services still use the workstation's [hosts-file mappings](../setup/local-access.md).

Stop the preview when finished:

```shell
docker compose -f dev/homepage/compose.yaml down
```

The files under `dev/` are outside Flux reconciliation. Logs are temporary, and Docker cannot write changes into the shared application configuration. After reviewing the preview, commit the intended config edits and merge them for Flux to deploy.

## Proxmox widget and private credentials

The Infrastructure card opens the Proxmox Tailscale address in the browser. Its [Proxmox widget](https://gethomepage.dev/widgets/services/proxmox/) calls the API from the Homepage server and shows VM counts plus CPU and memory usage. These are Proxmox host/cluster readings, distinct from the Kubernetes workload summary. This service widget is configured in `services.yaml`; the empty `proxmox.yaml` is for the separate per-VM/LXC integration and does not need duplicate credentials.

The workstation can resolve `proxmox.tail2395c1.ts.net`, but the Homepage pod could not resolve that MagicDNS name when checked on 2026-11-19. The widget therefore uses the reachable LAN API origin supplied through private Terraform inputs, while the card link keeps the Tailscale URL. No Tailscale component is added to Kubernetes. The pinned Homepage proxy accepts locally issued Proxmox certificates; no global TLS environment override is added.

Use the existing `api@pam!homepage` token with read-only permissions. The [upstream token setup](https://gethomepage.dev/configs/proxmox/#create-token) uses `PVEAuditor` on `/` with propagation, assigned both to the user and to the API token when Privilege Separation is enabled. The effective permissions are limited by both assignments. No VM-management or administrator role is needed for this dashboard.

Add this optional object to the ignored `iac/vault/terraform.tfvars`, preserving the other inputs:

```hcl
homepage_proxmox = {
  # Example LAN API origin; replace with your reachable address, without a trailing slash.
  url          = "https://192.168.0.50:8006"
  token_id     = "api@pam!homepage"
  token_secret = "replace-with-the-token-secret"
}
```

Obtain the full Token ID and secret from **Datacenter > Permissions > API Tokens**. Proxmox shows the secret only when the token is created; if it is lost, create a replacement rather than guessing it. Do not commit populated tfvars, state, or plan files. `sensitive` masks Terraform output; it does not encrypt local state.

Terraform manages `external-secrets/homepage/proxmox`. ESO maps its URL, token ID, and token secret into the `homepage-proxmox` Kubernetes Secret. The deployment imports those as `HOMEPAGE_VAR_PROXMOX_*` environment variables, and the shared YAML contains only substitution placeholders. The Secret is optional so Homepage itself can start before the widget is configured; the Proxmox widget will report an error until credentials are available. The ExternalSecret also requires the ESO controllers and Vault store to be installed.

Review and apply the Vault plan, merge the GitOps changes, then refresh ESO:

```shell
umask 077
terraform -chdir=iac/vault validate
terraform -chdir=iac/vault plan -out=tfplan
terraform -chdir=iac/vault apply tfplan
kubectl -n homepage annotate externalsecret homepage-proxmox force-sync="$(date +%s)" --overwrite
kubectl -n homepage get externalsecret homepage-proxmox -o 'custom-columns=NAME:.metadata.name,REFRESHED:.status.refreshTime,READY:.status.conditions[0].status'
```

Wait for a new refresh timestamp and Ready status before restarting Homepage, since environment variables are read at process startup:

```shell
kubectl -n homepage rollout restart deployment/homepage
kubectl -n homepage rollout status deployment/homepage --timeout=300s
```

For Docker, authenticate the workstation Vault CLI, then run the preview helper instead of plain Compose when testing this widget:

```shell
export VAULT_ADDR=http://vault.homelab.internal
vault login
./dev/homepage/preview.sh
```

The helper reads the same Vault record into its process environment and starts Compose with the shared config files. It creates no secret config copies or credential files. Avoid shell tracing and `docker compose config` with populated credentials because they can print secrets. Local Docker administrators can inspect container environment variables. Rerun the helper after a token rotation or an atomic config-file edit; plain Compose recreation without these exported variables starts a visual preview with empty Proxmox credentials.

## Tailscale and Cloudflare Tunnel widgets

Infrastructure includes the [Tailscale device widget](https://gethomepage.dev/widgets/services/tailscale/) and [Cloudflare Tunnel widget](https://gethomepage.dev/widgets/services/cloudflared/). Both call provider APIs from Homepage and add no agents or containers. Their cards appear alongside the other Infrastructure cards in the responsive row layout.

The single Tailscale card monitors the Proxmox device. Obtain its ID from the Tailscale admin console under **Machines > device > Machine Details > ID**. Configure optional `homepage_tailscale` in private tfvars with `device_id` and `api_token`. The token must be an API access token from the [Keys page](https://login.tailscale.com/admin/settings/keys), not an enrolment auth key. Standard Tailscale API access tokens have full API permissions and expire within 1–90 days; store them privately and rotate before expiry. The card displays only Last Seen and device-key Expires; its address is hidden for screen sharing. The `expires` field describes the device key, not this API token. See [Tailscale API authentication](https://tailscale.com/docs/reference/tailscale-api#authentication).

Configure optional `homepage_cloudflared` with `account_id`, `tunnel_id`, and `api_token`. Use the account and tunnel already managed by `cloudflared_credentials`, but create or reuse a separate Cloudflare API token with **Account > Cloudflare Tunnel > Read** restricted to that account. The connector's `TunnelSecret`, its credentials JSON, the workstation `cert.pem`, and a global API key are not widget API tokens. The card shows only tunnel status, with origin IP hidden for screen sharing; it opens the Zero Trust dashboard.

Terraform manages separate records at `external-secrets/homepage/tailscale` and `external-secrets/homepage/cloudflared`. Their separate ExternalSecret resources populate `homepage-tailscale` and `homepage-cloudflared` Kubernetes Secrets, supplying only `HOMEPAGE_VAR_*` values. The shared YAML contains placeholders. Review and apply a plan after filling the ignored tfvars inputs; after merge, wait for both ExternalSecrets to refresh and become Ready, then restart Homepage to load the environment variables.

The Docker preview helper reads both records from Vault alongside Proxmox. It warns and supplies empty values for optional fields that are unavailable, so the page can still start while setup is incomplete; the affected widgets will report errors. Rerun it after updating tokens. These widgets read provider status only and do not install Tailscale into Kubernetes, alter tailnet access, or change tunnel routing.

## Resource visibility

The Kubernetes information widget shows one cluster CPU/memory summary, with the separate node summary hidden, through [Metrics Server](../infrastructure/metrics-server.md). Cards use explicit namespaces and pod selectors for application readings. Linkding selects `app=linkding`; Shoutrrr selects `app.kubernetes.io/name=shoutrrr`. HTTP site checks indicate endpoint availability separately from pod resource readings.

The resource view shows current readings from Metrics Server without retaining history. Shoutrrr has an entry point but requires its Vault credentials and first-owner registration; Cloudflared provides the public HTTPS route for Shoutrrr.

Ingress discovery is disabled to avoid duplicate cards. Homepage omits its own shortcut and the Traefik card; no Traefik dashboard route is declared in this repository.

## Dashboard groups

The dashboard presents **Applications**, **Infrastructure**, and **Web** as three stacked, full-width sections on one overview, without tabs. Homepage's native row layout places cards across each section and wraps them responsively: Applications and Web allow up to six cards per row, while Infrastructure uses up to four columns below 1280px. On wider screens, Infrastructure uses four columns: Proxmox, Tailscale, and Cloudflare Tunnel each span two rows, with Flux above Vault in the remaining column. Simple Infrastructure links keep their natural height. Applications contains Linkding and Shoutrrr. Infrastructure contains Proxmox, Tailscale, Cloudflare Tunnel, the Flux UI, and Vault. Web contains ChatGPT and Gemini; future external dashboards and tools can be added to this group. These are external links rather than hosted workloads.

These cards are a selected set of entry points and resource views, not a pod inventory. External Secrets, CoreDNS, ServiceLB, Local Path Provisioner, and other controllers do not need individual shortcuts merely because they run in the cluster. Use the [infrastructure inventory](../infrastructure/index.md) and Flux for the broader picture.

Group names in `configs/services.yaml` must match the layout keys in `configs/settings.yaml`. Their headers are enabled so the grouping is visible. Endpoint checks remain enabled; an unavailable service should be investigated rather than made to look healthy by hiding its check. Screenshots should be captured after the intended services finish bootstrap and the current configuration is deployed.

## Verify

```shell
kubectl -n homepage rollout status deployment/homepage
kubectl -n homepage get pods,service,ingress
kubectl top pods -n homepage
```

Expect the deployment Ready, a matching Ingress, and resource readings once Metrics Server has collected them. If the page loads but a card fails, check that card's target component before treating it as a Homepage deployment failure.

See the [official Homepage documentation](https://gethomepage.dev/) for supported widgets and configuration options.
