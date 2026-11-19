---
name: update-architecture-diagram
description: Update this homelab's architectural SVG diagrams from its current GitOps configuration, preserving the established visual layout and documentation references.
---

# Update architecture diagrams

Maintain the shared full-system overview and focused traffic/secrets diagrams when the homelab's structure changes. This skill changes documentation assets; it does not deploy resources or establish live availability.

## Owning files

Run from the homelab repository root. The editable sources are `docs/assets/diagrams/sources/*.json`. The bundled helper [scripts/render-diagrams.py](scripts/render-diagrams.py) renders them into the SVG files in the parent directory using Python's standard library. Each source contains a title, description, canvas dimensions, groups, cards, connectors, and notes with explicit positions. The stable layout is intentional: update affected parts rather than redesigning all diagrams on every invocation.

README and `docs/architecture/index.md` share `architecture.svg`; traffic and secrets pages use their matching SVGs. Keep one source and one generated asset per diagram. Do not edit generated SVG text as the source of truth. Decorative banner artwork is separate from architecture and normally stays unchanged.

## Inspect the declared relationships

Read the relevant manifests before changing nodes or connectors:

- `gitops/clusters/lab/kustomization.yaml` and the included Flux group files establish activation and readiness ordering.
- `gitops/apps/kustomization.yaml` establishes the included applications.
- `gitops/infrastructure/core` contains the retained class and Flux UI ingress. The documentation's Infrastructure category also covers the separate secrets and monitoring groups; do not collapse them into this Flux group.
- The relevant component Kustomizations, Helm values, Ingresses, ExternalSecrets, and claims establish ownership and relationships. Inspect only what the requested change affects.
- `iac/vault/*.tf` and `iac/vault/eso/*.tf` explain Vault configuration ownership. Do not read private inputs, state, `.env`, tokens, snapshots, or actual credential values.

A directory does not mean a component is activated. K3s-provided components are not separate Flux installations. A declared resource does not prove successful runtime bootstrap. Preserve the distinction between request flow, reconciliation, readiness, secret delivery, and persistent data. Keep Linkding's existing default-class claim distinct from retained Vault/monitoring storage unless the owning manifests and requested scope actually change that relationship.

## Update and render

Change the affected JSON source cards, connectors, and accessible descriptions. Keep variable LAN IPs as placeholders, use stable in-cluster names when relevant, and mark inactive components separately. Keep the overview readable by putting detailed sequences in the focused diagrams or explanatory pages. If the configuration does not resolve a relationship, flag the ambiguity instead of inventing it.

Render and check the assets:

```shell
python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py
python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py --check
```

The check catches an export that no longer matches its editable source; it does not prove architectural accuracy. Review the relevant source-to-manifest relationships separately.

Inspect the rendered images at normal README width and in the documentation, checking text wrapping, connector placement, overlap, contrast, and the legend. Labels must remain readable without animation or a live cluster connection. Update links or nearby captions only when the structural change requires it; do not rewrite unrelated prose.

Report which relationships and assets changed, the verification performed, and any ambiguity or unavailable visual check. Do not apply Kubernetes changes, activate retained bundles, install a new renderer, capture private data, or commit/publish unless the user's request separately authorizes it.
