# Crossplane Drift Detection on Kubernetes

## Context
A platform engineer just declared an S3 bucket as a Kubernetes object. Five minutes
later, an over-eager teammate deleted it from the cloud console "to fix one thing."
In a Terraform shop, nobody notices until the next `plan` run — maybe tomorrow,
maybe never. Your task: prove that with Crossplane, the bucket comes back on its own,
within the reconcile interval, with no human in the loop.

> **Demo honesty note:** the "cloud" here is [LocalStack](https://localstack.cloud/)
> standing in for AWS S3 — same API, no cost. The Crossplane control loop is the
> real thing.

## Stack
Kubernetes (`kind`) + [Crossplane](https://www.crossplane.io/) v2 core + Upbound
`provider-aws-s3` + LocalStack + `awslocal` CLI (shorthand for `aws --endpoint-url http://localhost:4566`).

```bash
pipx install awscli-local   # one-time install (pipx manages the venv for you)
```

---

## Fast setup — do this BEFORE class (~5–10 min, mostly image pulls)
Needs Docker + [`kind`](https://kind.sigs.k8s.io/) + `kubectl` + [`helm`](https://helm.sh/)
+ `aws` CLI. All single-binary installs.

```bash
# Brings up Kind + LocalStack + Crossplane core + provider-aws-s3 + creds secret.
bash codebase/setup.sh
```

Wait until the script's `kubectl wait` returns. If it times out, re-run — image pulls
on a slow network can exceed 5 min.

**No time to set up?** You can still complete the worksheet by reading the manifests.

---

## Your task

The cluster is up but **no `ProviderConfig` is applied yet** — so Crossplane has
nowhere to send S3 calls. Open `codebase/providerconfig.yaml`: the structure is
there, but `spec.endpoint.url.static` is `FILL_ME_IN`. You will fill it in, apply,
then declare the bucket, then delete it out-of-band and watch Crossplane bring it
back.

### 0. Fill the gap and apply the config

Edit `codebase/providerconfig.yaml`. Replace `FILL_ME_IN` with the URL that points
to LocalStack **as reachable from inside the Kind cluster** (NOT from your laptop —
read the hint comment in the file).

```bash
kubectl apply -f codebase/providerconfig.yaml
kubectl apply -f codebase/runtimeconfig.yaml   # 15s reconcile, so drift heals on screen
```

### 1. Declare the bucket

```bash
kubectl apply -f codebase/bucket.yaml
kubectl get bucket my-multicloud-bucket -w
# wait for:  SYNCED=True   READY=True
```

If `SYNCED` stays `False` for more than ~60s, your endpoint URL is wrong. `Ctrl-C`,
`kubectl describe bucket my-multicloud-bucket | tail -n 20`, fix
`providerconfig.yaml`, `kubectl apply` it again.

Confirm on the "cloud" side:

```bash
awslocal s3 ls
# my-multicloud-bucket  ← here
```

### 2. Simulate drift (delete the bucket out-of-band)

```bash
bash codebase/simulate-drift.sh
```

The bucket is now gone from LocalStack but Kubernetes still holds the declared
truth. **Start a stopwatch.**

### 3. Watch reconciliation

```bash
kubectl get bucket my-multicloud-bucket -w
# SYNCED=False  ← controller detects divergence
# SYNCED=True   ← bucket recreated automatically (within the poll interval)
```

When `SYNCED` flips back to `True`, **stop the stopwatch**. Then:

```bash
kubectl describe bucket my-multicloud-bucket | tail -n 20
awslocal s3 ls   # bucket is back
```

### 4. Fill in `WORKSHEET.md`

Answer the questions in `WORKSHEET.md` — time-to-convergence, the Terraform vs
Crossplane comparison, and the honest caveat about what drift detection does and
doesn't guard.

---

## Deliverable

A terminal screenshot (or screen recording) showing the full arc with timestamps:

1. `kubectl apply -f bucket.yaml` → `SYNCED=True / READY=True`
2. `simulate-drift.sh` → bucket gone from `s3 ls`
3. `kubectl get -w` → `SYNCED=False` → `SYNCED=True`, plus the `describe` event log
4. Your measured **time-to-convergence** between the two `SYNCED` transitions.

Plus your completed `WORKSHEET.md`.
