# Applications

| Application | Activation | Access | Data |
| --- | --- | --- | --- |
| [Homepage](homepage.md) | Included | homepage.homelab.internal | Git-backed ConfigMap; temporary logs |
| [Linkding](linkding.md) | Included | linkding.homelab.internal | Existing 10 GiB local-path claim, unchanged |
| [Postiz](postiz.md) | Not included | No active route | Retained deployment design only |

`gitops/apps/kustomization.yaml` includes only Homepage and Linkding. The apps Flux group has no dependency on Vault or monitoring. Future applications needing operators or secrets should get their own dependency boundary rather than blocking these two applications.
