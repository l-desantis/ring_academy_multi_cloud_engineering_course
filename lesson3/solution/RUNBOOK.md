# Lesson 3 — Instructor Runbook: Crossplane Drift Detection (15 min live)

> Run `bash lesson3/codebase/setup.sh` BEFORE class. It pulls images
> (5–10 min on a cold network) and brings up the cluster + LocalStack +
> Crossplane core + provider + creds secret.

## Pre-flight (do this 5 min before students arrive)

> `awslocal` is a shorthand for `aws --endpoint-url http://localhost:4566`.
> Install once: `uv tool install awscli-local  (or: pipx install awscli-local)`
>
> **LocalStack auth token required (free):** LocalStack v4+ requires a token.
> Sign up at https://app.localstack.cloud, then `export LOCALSTACK_AUTH_TOKEN=<your-token>`.
> The `setup.sh` script will fail with a clear message if the token is missing.

```bash
# CRD is served?
kubectl explain bucket.s3.aws.upbound.io --recursive | head
# LocalStack reachable from the host?
awslocal s3 ls
# Provider Healthy?
kubectl get provider provider-aws-s3
# INSTALLED=True  HEALTHY=True  ← must see both before starting
```

If LocalStack is unreachable, `docker start localstack`.
If the provider isn't `HEALTHY`, `kubectl describe provider provider-aws-s3 | tail -n 20` and wait.
**Do not start the demo until the provider is HEALTHY** — students can't watch the bucket reconcile
if the provider can't reach LocalStack.

Pick the right ProviderConfig for your laptop and apply it:

- Mac / Windows: `kubectl apply -f lesson3/solution/manifests/providerconfig-mac-windows.yaml`
- Linux:         `kubectl apply -f lesson3/solution/manifests/providerconfig-linux.yaml`

Then apply the fast-poll config and wire it to the provider:

```bash
kubectl apply -f lesson3/codebase/runtimeconfig.yaml
kubectl patch provider provider-aws-s3 \\
  --type=merge \\
  -p '{"spec":{"runtimeConfigRef":{"name":"fast-poll"}}}'
# verify:
kubectl get provider provider-aws-s3 -o yaml | grep -A1 runtimeConfigRef
```

## Step 1 — Declare a resource via YAML (3 min)

```bash
kubectl apply -f lesson3/codebase/bucket.yaml
```

Open **two terminals side by side** — this is the visual payoff:

```bash
# Terminal 1 — Kubernetes side
kubectl get bucket my-multicloud-bucket -w
# wait for SYNCED=True  READY=True

# Terminal 2 — "Cloud" side, auto-refreshes every 2s
watch -n 2 awslocal s3 ls
```

**Talk track:** *No AWS Console. No `terraform apply`. Just a Kubernetes object.*
`SYNCED` means Crossplane has matched the cloud to your spec; `READY` means the
cloud resource reports healthy. Notice the bucket appears in Terminal 2 the moment
`SYNCED` goes `True` — that's the controller talking to LocalStack.

**Version note** (in case someone asks): this uses the cluster-scoped
`s3.aws.upbound.io/v1beta1` group — fully supported on Crossplane v2, chosen for
simplicity. The v2 namespaced form would be `s3.aws.m.upbound.io/v1beta1` plus a
`namespace:` field. Don't mix the two in one exercise. The `v1beta1` is the CRD's
maturity tag, independent of the Crossplane engine being v2.

## Step 2 — Simulate drift (4 min)

Keep both terminals open. In a **third terminal**:

```bash
bash lesson3/codebase/simulate-drift.sh
```

Point at Terminal 2 as the bucket vanishes from `watch awslocal s3 ls`.
Point at Terminal 1 as `SYNCED` flips to `False`. Start a visible stopwatch.

**Talk track:** This is the everyday disaster — someone with console / CLI access
"just fixes one thing" out-of-band. Kubernetes still holds the declared truth; the
cloud no longer matches it. In a Terraform shop, nobody finds out until the next
`plan` — which might be tomorrow's pipeline, or never.

## Step 3 — Watch reconciliation (5 min)

No commands needed — keep watching both terminals:

```bash
# Terminal 1:
# SYNCED=False  ← controller detects the cloud no longer matches the spec
# SYNCED=True   ← bucket recreated automatically (within the poll interval)
# Terminal 2: bucket reappears in awslocal s3 ls
```

Stop the stopwatch when `SYNCED` flips back to `True`. Then show the event log:

```bash
kubectl describe bucket my-multicloud-bucket | tail -n 20
```

**Talk track:** Nobody ran a command to fix this. The controller's watch loop
noticed the divergence and reconciled actual state back toward declared state — the
exact same control-loop mechanic Kubernetes uses to keep your Pods running, now
applied to a cloud primitive. *This is the watch loop, not eventual-on-next-plan
consistency.*

## Step 4 — Discussion (3 min)

|                         | Terraform                              | Crossplane                                |
|-------------------------|----------------------------------------|-------------------------------------------|
| **Execution model**     | One-shot, manual / pipeline trigger    | Continuous control loop                   |
| **Drift detection**     | Only on next `plan` run                | Automatic, within the poll interval       |
| **State**               | State file / remote backend            | etcd (Kubernetes API)                     |
| **K8s integration**     | External tool, separate auth           | Native operator (RBAC, GitOps)            |
| **Multicloud**          | Via providers                          | Via providers **+ Compositions**          |

**Land on the last row:** "Via providers" is table stakes — both tools have
AWS / GCP / Azure providers. Crossplane's real differentiator is the second half:
the platform team can **expose its own API**. A developer asks for an `AppBucket`
(or `AppDatabase`), and a Composition translates that into bucket + policy +
encryption + tags behind the scenes. The developer never writes S3 YAML. That's
the platform-engineering payoff this 1-bucket demo only hints at.

**The honest caveat** (and bridge to any governance discussion): Crossplane
reconciled a *change to a resource it manages*. If the same engineer had *created*
a brand-new bucket outside Crossplane, the controller would never see it — drift
detection guards the resources under management, not the ones provisioned around
it. That's a provisioning-path / governance problem, not a reconciliation one.

## Fallbacks

- **Provider not HEALTHY / bucket won't reconcile:** check the provider is actually
  referencing the fast-poll config: `kubectl get provider provider-aws-s3 -o yaml | grep -A1 runtimeConfigRef`.
  If absent: `kubectl patch provider provider-aws-s3 --type=merge -p '{"spec":{"runtimeConfigRef":{"name":"fast-poll"}}}'`
  and wait for the provider pod to restart.
- **Endpoint URL wrong (Linux):** `kubectl describe bucket … | tail -n 20` will
  show connection errors. Switch to `providerconfig-linux.yaml` and re-apply.
- **All else fails:** play the pre-recorded 30s screen capture of the reconcile.

## Reset between runs

```bash
kubectl delete -f lesson3/codebase/bucket.yaml || true
awslocal s3 rb s3://my-multicloud-bucket || true
```
