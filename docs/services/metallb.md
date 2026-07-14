---
icon: lucide/network
---

# MetalLB

MetalLB gives services a stable address on the home network. It runs in layer
2 mode and advertises one address for the Traefik LoadBalancer Service.

## Current implementation

| Property | Value |
|---|---|
| Helm chart | `metallb` `0.16.1` |
| Namespace | `metallb-system` |
| Address pool | `192.168.0.60/32` |
| Advertisement | Layer 2 |
| Active consumer | Traefik |

The controller manages address allocation, while the speaker advertises the
selected address from the node onto the LAN.

## Single-node control-plane advertisement

Kubernetes marks this control-plane node with
`node.kubernetes.io/exclude-from-external-load-balancers`. MetalLB honors that
label by default and will not advertise a LoadBalancer address from the node.
That behavior is useful in a multi-node cluster where worker nodes should
handle external traffic, but it leaves a single-node cluster with no eligible
speaker.

The first symptom was deceptive: the Traefik Service and application Ingresses
showed `192.168.0.60`, and workstation DNS resolved the application hostname to
that address, but HTTP requests failed with `No route to host`. Address
allocation by the MetalLB controller does not prove that a speaker is
announcing the address on the LAN.

The lab overlay explicitly permits the speaker to use the control-plane node:

```yaml
speaker:
  # This single-node cluster schedules its speaker on the control-plane node.
  ignoreExcludeLB: true
```

This value adds `--ignore-exclude-lb` to the MetalLB speaker. It is an
intentional single-node exception; a future multi-node cluster should revisit
whether external traffic belongs on control-plane nodes.

## Verify advertisement

First confirm that MetalLB allocated the expected address:

```shell
kubectl get service traefik --namespace traefik
```

Then verify the separate layer 2 announcement state:

```shell
kubectl get servicel2statuses.metallb.io --namespace metallb-system
kubectl describe service traefik --namespace traefik
```

The status must name an allocated node. The Service events should also include
an announcement such as:

```text
announcing from node "talos-9xy-zhb" with protocol "layer2"
```

Finally, test the complete DNS, LAN, ingress, and application path from a
workstation:

```shell
curl --fail --show-error http://homepage.homelab.internal/
```

A successful request confirms more than pod readiness: the hostname resolves
to `192.168.0.60`, the LAN can reach the VIP, Traefik matches the host rule, and
the Homepage Service has a working endpoint.

## Repository locations

- Helm release: `gitops/infrastructure/controllers/base/metallb`
- Lab values: `gitops/infrastructure/controllers/lab/metallb`
- Address pool and advertisement: `gitops/infrastructure/configs/lab/metallb`
- Health check: `gitops/clusters/lab/infrastructure-controllers.yaml`

## Dependencies

MetalLB requires working node networking. Traefik depends on the advertised
address for local ingress. See [Traffic flow](../architecture/traffic-flow.md).

## References

- [MetalLB troubleshooting](https://metallb.io/troubleshooting/)
