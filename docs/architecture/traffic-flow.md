---
icon: lucide/route
---

# Traffic flow

Most browser interfaces are private over the LAN. Shoutrrr is the sole public exception at `https://shoutrrr.hyperoot.dev`, served through Cloudflare Tunnel. Without a LAN DNS server, each workstation maps the internal hostnames to the K3s node's current LAN address in its own `/etc/hosts` file. That mapping is local to the workstation; it does not change DNS for other devices.

![Private LAN routing through Traefik alongside the Shoutrrr-only public HTTPS tunnel](../assets/diagrams/traffic-flow.svg)

The connection reaches the node on the requested port. K3s ServiceLB makes the Traefik LoadBalancer service available, and Traefik matches the HTTP hostname to an Ingress. The LAN application interfaces use HTTP; port 443 being available on Traefik does not mean certificates or HTTPS have been configured for every route.

## Where requests go

| Hostname | Destination | Access condition |
| --- | --- | --- |
| `shoutrrr.hyperoot.dev` | Shoutrrr via Cloudflared | Public HTTPS; application account required |
| `homepage.homelab.internal` | Homepage | Included application |
| `linkding.homelab.internal` | Linkding | Owner account required |
| `flux.homelab.internal` | Flux Operator's embedded web UI | Included core ingress |
| `vault.homelab.internal` | Vault | Initialization and unseal required |
| `grafana.homelab.internal` | Grafana | Monitoring credentials and chart ready |
| `prometheus.homelab.internal` | Prometheus | Monitoring ready; Traefik Basic Auth |

Alertmanager is cluster-internal. The Flux UI uses the existing operator service rather than another UI deployment. Hostname resolution does not prove that the destination is ready or provide an authentication boundary.

Follow [Local access](../setup/local-access.md) for internal hosts-file mappings. Shoutrrr uses public DNS, and Cloudflared forwards directly to its cluster-internal Service rather than through Traefik. The old Shoutrrr LAN Ingress redirects to its public HTTPS hostname. The tunnel routes no other service; unmatched hostnames return 404. Tailscale remains unused, and the private interfaces still depend on the router/firewall not forwarding LAN ports publicly.

Cloudflare terminates browser TLS and the connector maintains an encrypted outbound-established tunnel. The final connector-to-Service hop is HTTP within Kubernetes. Shoutrrr trusts proxy headers from the current pod network and generates HTTPS URLs. See [Cloudflared](../infrastructure/cloudflared.md) for credentials, dependencies, resource limits, and recovery.
