---
icon: lucide/panels-top-left
---

# Applications

Applications are the tools used by people. They live under `gitops/apps`, while administrative capabilities belong to [Infrastructure](../infrastructure/index.md). A web UI alone does not make a component an application: Grafana and the Flux UI support administration.

| Application | What it does | Declared activation | Initial configuration |
| --- | --- | --- | --- |
| [Homepage](homepage.md) | Dashboard, shortcuts, and current Kubernetes resource readings | Included | Review service cards and workstation hostname access |
| [Linkding](linkding.md) | Personal bookmark collection | Included | Create an owner account on a new installation |
| [Shoutrrr](shoutrrr.md) | Social scheduling trial | Included in its own group | Requires Vault credentials and first-owner registration; SQLite in the application pod |
| [Postiz](postiz/index.md) | Previous scheduling trial | Entrypoint commented | Data retained; operator-controlled rollback |

`gitops/apps/kustomization.yaml` includes only Homepage and Linkding. Their Flux group has no dependency on Vault or monitoring. Future applications needing operators or secrets should get their own readiness boundary rather than blocking these independent applications.

Follow [Setup](../setup/index.md) for the initial journey. Each application page explains its own configuration and data. Declared activation describes the manifests, not a live availability guarantee.
