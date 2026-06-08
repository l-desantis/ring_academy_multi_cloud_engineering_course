# Crossplane Drift Worksheet — Model Answers

## Step 1 — Time to convergence
- **Measured time-to-convergence:** typically 5–25 seconds with the `fast-poll`
  runtimeconfig applied. (Variation comes from where in the poll window the drift
  happened.)
- **Knob that determined this:** the `--poll=15s` arg on the provider's package
  runtime, wired via `DeploymentRuntimeConfig/fast-poll`. The provider polls each
  managed resource on this interval and acts the next time it sees divergence.
- **Default upper bound without that knob:** roughly **1 minute** (the
  provider-aws-s3 default poll interval at the time of writing). Convergence can be
  up to that long even though the controller itself is healthy.

## Step 2 — Evidence from the event log
Accept any answer that cites:
- **Noticed drift:** an event of type `Warning` / reason `CannotObserveExternalResource`
  *or* a transition log line where `SYNCED` flipped to `False`.
- **Acted on it:** an event of reason `CreatedExternalResource` (the controller
  recreated the bucket) — same reason as the very first create, which is itself a
  teaching point: reconciliation is the same code path as creation.

## Step 3 — Terraform vs Crossplane

| Dimension              | Terraform                                | Crossplane                                  |
|------------------------|------------------------------------------|---------------------------------------------|
| Execution model        | One-shot, manual / pipeline trigger      | Continuous control loop                     |
| Drift detection        | Only on next `plan` run                  | Automatic, within the poll interval         |
| State storage          | State file / remote backend (S3, TFC, …) | etcd, via the Kubernetes API                |
| Kubernetes integration | External tool, separate auth & RBAC      | Native operator — uses cluster RBAC, GitOps |
| Multicloud story       | Via providers                            | Via providers **plus Compositions**         |

## Step 4 — The honest caveat
Crossplane only reconciles resources it **manages** (those declared as `kind: Bucket`
etc. in the cluster). If someone provisions a brand-new bucket directly in the
cloud, Crossplane never sees it — there's no `Bucket` object in etcd to compare
against. That's a *provisioning-path / governance* problem (lock down IAM, force all
provisioning through the platform API), not a reconciliation one.

## Step 5 — Multi-cloud tie-back
A *Composition* lets the platform team publish their own Kubernetes API — e.g.
`kind: AppBucket` — that internally fans out to a bucket + IAM policy + encryption
config + standard tags + (optionally) a parallel GCS bucket on GCP. Developers
write one short YAML; the platform owns the cloud-specific shape and can swap
providers underneath without changing the developer-facing API. Raw providers give
you 1:1 cloud-resource mappings; Compositions give you a *product surface*.
