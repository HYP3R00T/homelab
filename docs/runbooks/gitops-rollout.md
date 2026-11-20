---
icon: lucide/rocket
---

# Roll out the K3s GitOps configuration

This runbook describes deployment through the watched Git branch. Editing the feature branch does not apply these changes. Do not merge the whole change without checking the intended activation and existing storage. No secret values are generated or written by these manifests.

## Before rollout

Check the selected context, Flux inventory, running applications, and existing volume policies. Back up application data before any operation that changes storage ownership. Linkding's namespace, Deployment, Service, Ingress, and claim identities must remain unchanged.

```shell
kubectl config current-context
flux get kustomizations -A
kubectl get pods -A
kubectl get pvc -A
kubectl get pv
kubectl top nodes
kubectl top pods -A
```

Record the current Git revision for rollback. The cleanup can be reviewed in stages: NVIDIA removal, duplicate platform removal and layout changes, Flux ingress and retained class, secret bootstrap and Homepage. The checked-in dependency graph enforces runtime ordering; Git commits do not substitute for those readiness checks.

## Core infrastructure and applications

Once the configuration reaches main, check infrastructure and apps independently. Core creates only the retained class and Flux ingress. It does not replace K3s's ingress, storage controller, or metrics server.

```shell
flux get kustomizations apps infrastructure
kubectl get ingress -A
kubectl get storageclass local-path-retain
kubectl get pvc -n linkding
```

Follow [local access](../setup/local-access.md) to map the internal service hostnames to your node's current LAN address in the workstation hosts file. Open Homepage, verify Linkding's existing bookmarks, and open Flux Status. Retained application URLs can remain unavailable until their bootstrap stage completes.

## Vault and ESO

The secrets group installs the two Helm releases. Use [Vault bootstrap](vault-bootstrap.md) to initialize only a new Vault, unseal it, and configure Kubernetes auth with iac/vault. Never reinitialize retained data or print credentials into build logs.

```shell
flux get kustomizations secrets secret-store
flux get helmreleases -A
kubectl get clustersecretstore vault
```

The secret-store group waits for the store to become Ready. This can take longer than its reconciliation timeout while operator-driven bootstrap is incomplete; Flux retries. Do not make apps depend on the store to hide this expected state.

## CloudNativePG and Shoutrrr

The `cnpg` group installs the operator after core infrastructure. Shoutrrr does not use CNPG; it waits for retained storage and the secret store, then runs SQLite inside its application container.

Follow [Shoutrrr bootstrap](../apps/shoutrrr.md) to populate its Vault record, configure its public HTTPS tunnel, and register the first owner. The application uses `https://shoutrrr.hyperoot.dev` through Cloudflared. Provider credentials and external OAuth/media requirements are separate from pod startup.

```shell
flux get kustomizations cnpg shoutrrr
kubectl -n cnpg get helmrelease,pods
kubectl -n shoutrrr get externalsecrets,pods,pvc
```

Shoutrrr requests 256 MiB RAM and has a 768 MiB limit, with one web worker and one queue worker. Measure startup, uploads, publishing, and node pressure with `kubectl top`. Resource requests do not prove that simultaneous runtime peaks fit on this VM.

## Acceptance

Compare node and per-workload CPU/memory readings at idle and under ordinary application use using `kubectl top nodes` and `kubectl top pods -A`. Homepage uses the same Metrics Server API. Historical metrics and alerting are not installed.

Check application availability, restarts, OOM kills, pending pods, and node pressure before adding workloads. Resource requests do not prove that simultaneous runtime peaks fit on this VM. Verify persistence using the application-specific backup and recovery procedures.

## Rollback

Restore reviewed manifests through Git. For a running Helm release that must be paused, suspend its reconciliation before changing runtime state; suspending Flux alone does not stop pods. Do not delete a namespace or claim as a rollback shortcut. Reverting a commit that removes a HelmRelease can uninstall its workloads; inspect pruning and Helm ownership first. Retained volumes still require deliberate rebinding on recovery. Keep the core retained class and application data during rollback.

Cloudflared is included for Shoutrrr only. Tailscale and agent workloads are not activated by this rollout. CNPG and Shoutrrr are included but require their documented readiness and bootstrap checks.
