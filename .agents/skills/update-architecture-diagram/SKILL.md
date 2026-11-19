---
name: update-architecture-diagram
description: Update this homelab's D2 architecture and flow diagrams from its GitOps configuration, render self-contained SVGs, and maintain the relevant documentation references.
---

# Update architecture diagrams

Maintain the shared system overview and focused traffic/secrets flows when the homelab's structure changes. This is documentation work, not deployment or a live availability audit.

## Sources and renderer

The editable sources are `docs/assets/diagrams/sources/*.d2`. The matching SVGs in the parent directory are generated assets. README and `docs/architecture/index.md` share `architecture.svg`; traffic and secrets pages use their matching exports. Decorative banner artwork is separate.

Use the pinned D2 version in `mise.toml` with its bundled ELK layout engine. The helper [scripts/render-diagrams.py](scripts/render-diagrams.py) renders all sources to temporary files before replacing generated SVGs. It bundles icons into the output, checks export freshness, and uses stable layout flags. Do not hand-edit generated SVGs or restore the old JSON/coordinate renderer.

Service icons are local files under `docs/assets/diagrams/icons`. `credits.json` records their upstream source URLs and revisions, with license copies beside it. Preserve those records and add provenance for new assets. Prefer the product's actual artwork over a similarly named service logo. Rendered SVGs must not depend on a CDN or workstation file path.

## Inspect the declared relationships

Read the relevant manifests before changing nodes or connectors:

- `gitops/clusters/lab/kustomization.yaml` and included Flux groups establish activation and readiness ordering.
- `gitops/apps/kustomization.yaml` establishes included applications.
- `gitops/infrastructure/core` contains the retained class and Flux UI ingress. The Infrastructure category also covers separate secrets and monitoring groups; do not collapse those into this Flux group.
- Component Kustomizations, Helm values, Ingresses, ExternalSecrets, and claims establish ownership and relationships. Read only what the change affects.
- `iac/vault/*.tf` and `iac/vault/eso/*.tf` explain Vault configuration ownership. Do not read private inputs, state, `.env`, tokens, snapshots, or credential values.

A directory is not activation, and a declared resource is not proof of successful bootstrap. K3s-provided components are not extra Flux installations. Keep Linkding's existing default-class claim distinct from retained Vault/monitoring storage unless the requested change actually migrates it.

The overview is a compact component/ownership map: Ubuntu encloses K3s, and K3s encloses Applications and Infrastructure. Show only a simple host-data block outside K3s if storage context is needed. Keep packaged capabilities, PV/PVC objects, detailed storage policies, and disabled services out of this overview; explain them in focused pages or diagrams. K3s is the cluster boundary, not an infrastructure application.

Use consistent service-icon boxes and preserve each logo's aspect ratio. Vendored SVGs use square canvases with their original viewBox and `preserveAspectRatio="xMidYMid meet"`; never stretch a logo to fill a box. An SVG without a viewBox must be corrected from its intrinsic dimensions before use. Set both grid rows and columns for service grids to avoid D2 expanding individual image cells. Check the rendered visual size as well as nominal width and height. Ubuntu and K3s may have top-left container icons, with centered titles and enough header space to prevent overlap. Use plain component names in the overview; put bootstrap and runtime status in the accompanying documentation. Alertmanager is intentionally omitted from this overview, not disabled in deployment. Avoid long text or additional boxes that turn the overview into a vertical inventory. Inclusion in reconciliation is not proof of runtime readiness.

## Edit and verify

Update affected D2 groups, labels, and relationships, preserving the established layout and color vocabulary where possible. Keep variable LAN addresses as placeholders and stable in-cluster names literal. If manifests do not resolve a relationship, report the ambiguity rather than inventing one.

From the repository root:

```shell
mise install d2
mise exec -- d2 fmt docs/assets/diagrams/sources/*.d2
mise exec -- python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py
mise exec -- python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py --check
```

If a pinned binary is already available outside mise, set `D2_BIN` to its path when running the Python helper. The helper checks its version. No browser, Node installation, PNG exporter, or extra layout plugin is needed for SVG output.

The freshness check re-renders D2 and compares bytes; it does not prove architectural accuracy. Review the affected relationships against manifests separately. Inspect the SVGs at normal article/README width and full size, checking labels, service logos, grouping, overlap, and connector routing. Keep source labels readable without motion and preserve accessible Markdown image descriptions.

Update links and captions only when the structural change requires them. Report the changed relationships, generated assets, verification, and any unavailable visual check. Do not deploy, activate inactive bundles, handle credentials, rewrite unrelated prose, or commit/publish unless separately requested.
