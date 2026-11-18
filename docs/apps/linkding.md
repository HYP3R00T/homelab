# Linkding

Linkding is the owner's private bookmark application at `http://linkding.homelab.internal`. Its bundle is `gitops/apps/linkding`; it uses image sissbruecker/linkding:1.45.0 and service linkding-service:9090.

The cleanup preserves its namespace, Deployment, Service, Ingress, PVC name, and resource configuration. The container runs as UID/GID 33 and mounts /etc/linkding/data. Its existing 10 GiB claim uses the K3s default local-path class; the inspected PV has Delete reclaim policy. Do not delete this claim or assume it inherited the newly introduced retained class. A policy migration for existing application data is a separate operation requiring a backup and explicit scope.

K3s ServiceLB and Traefik provide LAN access. No public tunnel is activated. Homepage selects its pods by app=linkding to show live CPU/memory.

For a new installation only, create the owner account interactively after the pod is Ready:

```shell
kubectl exec --interactive --tty --namespace linkding deployment/linkding-deployment -- python manage.py createsuperuser
```

Do not recreate an existing account or put credentials in Git. Read [storage recovery](../runbooks/storage-recovery.md) before changing persistent data.
