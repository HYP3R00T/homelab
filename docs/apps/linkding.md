---
icon: lucide/bookmark
---

# Linkding

Linkding is the owner's private bookmark collection. Flux deploys one instance with local persistent storage, and Homepage links to it with current pod resource readings.

| Property | Configuration |
| --- | --- |
| Owner | Flux apps group |
| Activation | Included, independent of Vault |
| Image | `sissbruecker/linkding:1.45.0` |
| Namespace | `linkding` |
| Browser access | `http://linkding.homelab.internal` |
| Internal service | `linkding-service:9090` |
| Manifests | `gitops/apps/linkding` |
| Data | `linkding-data` PVC mounted at `/etc/linkding/data` |

## Initial setup

Configure [local hostname access](../setup/local-access.md), then wait for the application. A new deployment does not create its owner account automatically:

```shell
kubectl -n linkding rollout status deployment/linkding-deployment
kubectl exec --interactive --tty --namespace linkding deployment/linkding-deployment -- python manage.py createsuperuser
```

Enter the requested account details at the interactive prompts, then sign in through the browser. Run account creation only when a new owner account is needed; an existing installation keeps its account in persistent data. Keep credentials outside Git.

## Persistence

The existing 10 GiB claim uses the K3s default `local-path` class. It is preserved rather than migrated to the new retained class. The inspected existing PV used Delete reclaim policy; check the actual bound PV before any storage operation. Deleting the claim can delete data.

The container runs as UID/GID 33. Backups and restoration must preserve usable ownership and permissions. Read [storage recovery](../runbooks/storage-recovery.md) before changing the claim or reinstalling K3s. No public tunnel is activated for Linkding.

## Verify

```shell
kubectl -n linkding get pods,pvc,service,ingress
kubectl top pods -n linkding
```

Expect the pod Ready, the claim Bound, and the hostname reachable. After signing in, create and reopen a bookmark to verify the application rather than relying only on pod status.

See [Linkding's official installation guidance](https://linkding.link/installation/) for account management and other supported configuration.
