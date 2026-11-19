---
icon: lucide/blocks
---

# Postiz architecture

Postiz is retained but inactive. Its individual resource files live in `gitops/apps/postiz` and are assembled by its Kustomization. Neither the apps root nor an active Flux group includes it.

| Resource | Purpose |
| --- | --- |
| Namespace and three Deployments | Postiz web application, Redis, Temporal |
| Three Services | Internal application, Redis, and Temporal endpoints |
| Temporal ConfigMap | Dynamic Temporal settings |
| Four ExternalSecrets | Application, Redis, and database bootstrap credentials |
| Two PVCs | Uploads and Redis state |
| CloudNativePG Cluster | One PostgreSQL instance |
| Two CloudNativePG Database resources | Temporal persistence and visibility databases |
| Ingress | Local application route if deliberately activated |

The Cluster bootstraps the postiz database and owner. Its managed roles include temporal. CloudNativePG manages database creation; it must be installed before these CRs are reconciled. External Secrets must synchronize credentials before their consumers can start successfully. The total application cost includes all three Deployments and PostgreSQL, not just the Postiz web pod.

Future activation must first prepare CNPG, the Vault store, approved credentials, and storage recovery. It needs its own Flux dependency boundary so its bootstrap does not block Homepage and Linkding. The retained public URL and provider callback values must be reviewed for the intended private/public access model before deployment. The retained configuration does not create an owner account, enable providers, or publish routes.
