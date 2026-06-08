# Crossplane Drift Worksheet

## Step 1 — Time to convergence
You started a stopwatch when you ran `simulate-drift.sh` and stopped it when
`SYNCED` flipped back to `True`.

- Measured time-to-convergence: ____ seconds
- What configuration knob determined this number? (Hint: look at
  `codebase/runtimeconfig.yaml`.) ____
- Without that knob, what would the default upper bound be? ____

## Step 2 — Evidence from the event log
Paste the last 3–5 lines of `kubectl describe bucket my-multicloud-bucket | tail -n 20`
below, then answer:

```
<paste here>
```

- Which event proves the controller *noticed* drift? ____
- Which event proves the controller *acted* on it? ____

## Step 3 — Terraform vs Crossplane
Fill in your understanding of how each tool behaves:

| Dimension              | Terraform | Crossplane |
|------------------------|-----------|------------|
| Execution model        |           |            |
| Drift detection        |           |            |
| State storage          |           |            |
| Kubernetes integration |           |            |
| Multicloud story       |           |            |

## Step 4 — The honest caveat
Crossplane reconciled a *change to a resource it manages*. In one or two sentences:
what kind of drift does it **not** catch, and why is that a governance / provisioning
problem rather than a reconciliation one?

____

## Step 5 — Multi-cloud tie-back
This demo used one provider (S3 via LocalStack). In one or two sentences: what does
a Crossplane *Composition* let a platform team expose to developers that a raw
provider does not? Give a one-line example (e.g. `kind: AppBucket`).

____
