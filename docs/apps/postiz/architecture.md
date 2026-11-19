---
icon: lucide/blocks
---

# Postiz architecture

Postiz is included through its own Flux group. Its individual resource files live in `gitops/apps/postiz` and are assembled by its Kustomization. The apps root keeps Homepage and Linkding independent; `gitops/clusters/lab/postiz.yaml` includes this bundle after the `cnpg` and `secret-store` groups become ready.

| Resource | Purpose |
| --- | --- |
| Namespace and three Deployments | Postiz web application, Redis, Temporal |
| Three Services | Internal application, Redis, and Temporal endpoints |
| Temporal ConfigMap | Dynamic Temporal settings |
| Four ExternalSecrets | Application, Redis, and database bootstrap credentials |
| Two PVCs | Uploads and Redis state |
| CloudNativePG Cluster | One PostgreSQL instance |
| Two CloudNativePG Database resources | Temporal persistence and visibility databases |
| Ingress | Private LAN application route |

The Cluster bootstraps the postiz database and owner. Its managed roles include temporal. CloudNativePG manages database creation; it must be installed before these CRs are reconciled. External Secrets must synchronize credentials before their consumers can start successfully. The total application cost includes all three Deployments and PostgreSQL, not just the Postiz web pod.

The dedicated group waits for operator readiness and a working secret store. Populate the Postiz Vault record as described in [bootstrap](index.md#bootstrap-prerequisites). The application uses the private LAN hostname; initial owner registration and social provider setup remain separate from deployment. New persistent data uses the retained local class.
