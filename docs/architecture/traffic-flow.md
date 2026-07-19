---
icon: lucide/route
---

# Traffic Flow

The platform has separate paths for local ingress and public access. Both end
at ordinary Kubernetes Services; applications do not need to know which path a
request used.

## Local network

```mermaid
flowchart TB
    Client[LAN client] --> DNS[homelab.internal DNS]
    DNS --> VIP[MetalLB 192.168.0.60]
    VIP --> Traefik[Traefik]
    Traefik --> Homepage[Homepage service]
    Traefik --> Linkding[Linkding service]
    Traefik --> Postiz[Postiz service]
    Traefik --> Vault[Vault service]
```

MetalLB advertises a single address, `192.168.0.60`. Traefik receives traffic
on that address and selects a backend from the request hostname.

## Public application access

```mermaid
flowchart TB
    Browser[Internet browser] --> Edge[Cloudflare edge]
    Edge --> Tunnel[homelab tunnel]
    Tunnel --> Connector[Cloudflared pod]
    Connector --> LinkdingService[linkding-service:9090]
    Connector --> PostizService[postiz:5000]
    LinkdingService --> Linkding[Linkding]
    PostizService --> Postiz[Postiz]
```

The tunnel routes `linkding.hyperoot.dev` and `postiz.hyperoot.dev` to their
cluster Services. The tunnel is outbound-only, so the home router does not
expose an inbound application port.

See [MetalLB](../services/metallb.md), [Traefik](../services/traefik.md), and
[Cloudflared](../services/cloudflared.md) for ownership details.
