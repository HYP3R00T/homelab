---
icon: lucide/ethernet-port
---

# Access services on the LAN

This homelab does not run a LAN DNS server. Instead, the accessing workstation maps internal service hostnames to the K3s node's current LAN address in `/etc/hosts`. Traefik uses the hostname in each request to select the matching Ingress.

## Add the host mappings

Find the node address with `kubectl get nodes -o wide` or your existing network administration tools. On the workstation, edit the hosts file:

```shell
sudoedit /etc/hosts
```

Use this general format, replacing the placeholder with your node's LAN IP. The hostname must match the service's Ingress:

```text
<K3S_NODE_IP> <service>.homelab.internal
```

For the included browser interfaces, use your actual IP with these aliases. The following address is only an example; do not paste the placeholder or use an unrelated IP:

```text
# Example: replace 192.168.0.61 with your K3s node's current LAN IP
192.168.0.61 homepage.homelab.internal linkding.homelab.internal flux.homelab.internal
192.168.0.61 vault.homelab.internal grafana.homelab.internal prometheus.homelab.internal
```

Preserve other hosts-file entries. If an alias already exists, update its mapping rather than leaving conflicting entries. Each device needs its own resolution mechanism and LAN connectivity. If the node's address changes, update these mappings. This does not route all workstation DNS through the cluster.

## Available interfaces

| Hostname | Purpose | Before it is usable |
| --- | --- | --- |
| `homepage.homelab.internal` | Personal dashboard | Homepage deployment Ready |
| `linkding.homelab.internal` | Bookmarks | Deployment Ready and [owner account created](../apps/linkding.md#initial-setup) |
| `shoutrrr.hyperoot.dev` | Social publishing over HTTPS | [Shoutrrr setup](../apps/shoutrrr.md), Cloudflared and public DNS ready |
| `flux.homelab.internal` | GitOps status | Flux Operator and core ingress ready |
| `vault.homelab.internal` | Secret administration | Vault deployment, initialization, and unseal |
| `grafana.homelab.internal` | Metrics dashboards | [Vault and monitoring setup](../runbooks/vault-bootstrap.md) complete |
| `prometheus.homelab.internal` | Metric queries | Monitoring Ready; Basic Auth credentials available |

Open the internal interfaces with `http://`. Shoutrrr uses `https://shoutrrr.hyperoot.dev` through public DNS and requires no hosts-file entry; its former internal route redirects to that canonical address. This configuration does not provide certificates for these names. An included hostname is not evidence that its workload has completed bootstrap.

## Verify resolution and routing

```shell
getent hosts homepage.homelab.internal
kubectl get ingress -A
curl -I http://homepage.homelab.internal
```

The first command should return your node address. The Ingress list should show the hostname and `traefik` class. An HTTP response confirms a request reached an endpoint, but use the component's health checks to establish that it is working.

| Symptom | What to check |
| --- | --- |
| Hostname does not resolve | Hosts entry on this device, spelling, conflicting aliases |
| Connection refused or times out | LAN reachability, current node address, firewall, Traefik/ServiceLB |
| Traefik 404 | Hostname and path match an Ingress; use the hostname rather than just the IP |
| 502 or 503 | Backend pods, Services, endpoints, and bootstrap dependencies |
| Prometheus 401 | Expected Basic Auth gate; use the configured credential |
| Browser opens but login fails | Component account/bootstrap configuration, not name resolution |

Inside Kubernetes, services use cluster DNS such as `vault.vault.svc.cluster.local`. Those names do not rely on workstation hosts mappings. A future LAN DNS choice would replace the workstation mapping procedure; it is not required by this design.
