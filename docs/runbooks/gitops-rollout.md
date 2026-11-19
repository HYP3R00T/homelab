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

Record the current Git revision for rollback. The cleanup can be reviewed in stages: NVIDIA removal, duplicate platform removal and layout changes, Flux ingress and retained class, secret bootstrap, monitoring, and Homepage. The checked-in dependency graph enforces runtime ordering; Git commits do not substitute for those readiness checks.

## Core infrastructure and applications

Once the configuration reaches main, check infrastructure and apps independently. Core creates the retained class and the Flux/Traefik administration routes. It does not replace K3s's ingress, storage controller, or metrics server.

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

## Monitoring credentials and chart

The operator supplies or approves the Grafana and Prometheus credentials using the existing [monitoring credential procedure](../infrastructure/kube-prometheus-stack.md#credentials). Neither Terraform nor GitOps creates those values automatically.

```shell
kubectl get externalsecrets -n monitoring
flux get kustomizations monitoring-secrets monitoring monitoring-monitors
flux get helmreleases -n monitoring
kubectl get pods,pvc -n monitoring
```

Both ExternalSecrets must be Ready before the chart starts. Verify all three monitoring PVs have Retain and all StatefulSet claim-retention policies keep claims on deletion and scale-down. Read [storage recovery](storage-recovery.md) before testing recovery. Do not test by deleting a production claim.

## CloudNativePG and Postiz

The `cnpg` group installs the operator after core infrastructure. The separate `postiz` group waits for CNPG and the secret store, then applies its credentials, database, Redis, Temporal, uploads, and application resources. It does not block Homepage or Linkding.

Follow [Postiz bootstrap](../apps/postiz/index.md) to populate its Vault record, configure LAN access, and create the owner account. The application is configured for private HTTP, not the former public hostname. Provider credentials and external OAuth requirements are separate from pod startup.

```shell
flux get kustomizations cnpg postiz
kubectl -n cnpg get helmrelease,pods
kubectl -n postiz get externalsecrets,cluster,database,pods,pvc
```

New Postiz volumes use the retained class. Keep the trial resource limits and measure actual usage: the application stack has 1088 MiB of requests, excluding the 128 MiB operator request, alongside the existing monitoring budget. Resource requests do not prove that simultaneous runtime peaks fit on this VM.

## Acceptance

Open Grafana and verify node and individual pod CPU/memory history. Check Prometheus /targets for kubelet/cAdvisor, node exporter, kube-state-metrics, Flux, Vault, ESO, and K3s Traefik. Intentionally absent scheduler, controller-manager, etcd, and kube-proxy targets should not generate false failures. A Ready Helm release is not sufficient evidence that the targets work.

Compare the VM and per-workload CPU/memory at idle and under ordinary application use. Keep existing allocations and retention initially: Prometheus 10 days and 8GB, Alertmanager 120h. Notifications are intentionally not delivered; do not expect a receiver until one is chosen later. No fixed 2 GiB agent capacity is promised.

During a controlled persistence test, record a historical query result, replace only the Prometheus pod, wait for it to become Ready, and verify that earlier data remains. Check Grafana state the same way. Record results before changing resource allocations. Investigate OOM kills, restarts, pending pods, disk pressure, or unavailable applications before proceeding.

## Rollback

Restore reviewed manifests through Git. For a running Helm release that must be paused, suspend its reconciliation before changing runtime state; suspending Flux alone does not stop pods. Do not delete a namespace or claim as a rollback shortcut. Reverting a commit that removes a HelmRelease can uninstall its workloads; inspect pruning and Helm ownership first. Retained volumes still require deliberate rebinding on recovery. Keep the core retained class and data even if monitoring is temporarily disabled.

Cloudflared, Tailscale, and agent workloads are not activated by this rollout. CNPG and Postiz are included but still require their documented readiness and bootstrap checks.
