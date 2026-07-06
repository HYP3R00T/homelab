---
icon: lucide/lock-keyhole
---

# Vault

Vault is the secret storage backend for this homelab.

Its job is to hold values that should not live directly in Git, such as API tokens that other services need at runtime.

## What it depends on

- Core infrastructure from `clusters/lab/infrastructure-controllers.yaml`
- The Vault overlay in `infrastructure/configs/lab/vault`

## What depends on it

- `external-secrets`, through `clusters/lab/infrastructure-controllers.yaml`

## Where it is activated

- `clusters/lab/infrastructure-controllers.yaml`
- `clusters/lab/infrastructure-configs.yaml`
- `infrastructure/configs/lab/vault/kustomization.yaml`
- `infrastructure/configs/lab/vault/kustomization.yaml`
- `infrastructure/controllers/base/vault/`

## Important note

Applying Vault is only the first half of the setup.

External Secrets also needs Vault to be bootstrapped with:

- a KV mount for the shared secret path
- Kubernetes auth enabled
- a role for the External Secrets Operator
- policies that allow the operator to read the expected paths

Until that bootstrap work is done, Vault may be running while downstream secret consumers still fail to read values.
