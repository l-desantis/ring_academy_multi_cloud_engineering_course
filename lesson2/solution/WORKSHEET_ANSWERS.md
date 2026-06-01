# Worksheet — Model Answers

## Step 1 — Replicas vs. Weight
- Observed v2 share ≈ 10% (Phase 1 weights 90/10).
- It is NOT 1:3 because Istio routes by the **weights in the `VirtualService`**, not by pod
  count. The DestinationRule subsets + VS weights decide the split; replicas only affect how
  much capacity each version has to *serve* its share, not how big the share is.

## Step 2 — Per-phase observations
| Phase | Weights (v1 / v2) | Observed v2 share | Redeploy needed? |
|-------|-------------------|-------------------|------------------|
| 1 Launch  | 90 / 10  | ~10% | No |
| 2 Promote | 50 / 50  | ~50% | No |
| 3 Full    | 0 / 100  | ~100% | No |
| 4 Fault   | 0 / 100 + 50% abort | ~50% of v2 = 500s | No |
| 5 Rollback| 100 / 0  | ~0% (all clean v1) | No |

## Step 3 — Decision gate
| Signal | Promote if… | Roll back if… |
|--------|-------------|---------------|
| Error rate (5xx)      | v2 ≤ v1 | v2 > 5% for 2+ min |
| P99 latency           | v2 within ~10% of v1 | v2 P99 > 1000ms for 2+ min |
| Conversion (business) | stable | drops > 5% |
Automated via Prometheus alert rules (`CanaryHighErrorRate`, `CanaryHighLatency`) wired to a
controller (e.g. Flagger / Argo Rollouts) that adjusts the VS weight automatically — the
rollback decision becomes code, not a human watching a dashboard.

## Step 4 — Multi-cloud tie-back
With an Istio multi-primary mesh across EKS and GKE, the same `VirtualService` weights shift
traffic proportionally across providers. The canary split should mirror the capacity split
(e.g. 90% AWS / 10% GCP), so the canary is validated *across* clouds, not just on one.
