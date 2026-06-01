# Canary Worksheet

## Step 1 — Replicas vs. Weight
v1 runs 3 pods, v2 runs 1 pod. In Phase 1 you set v2 to a small traffic slice.
- What v2:v1 ratio did you observe in the loadgen stream? ____
- Why is it NOT 1:3 (the pod ratio)? Explain what actually controls the split.

## Step 2 — Per-phase observations
Fill in what you saw at each phase:

| Phase | Weights (v1 / v2) | Observed v2 share in stream | Redeploy needed? |
|-------|-------------------|-----------------------------|------------------|
| 1 Launch  |  |  |  |
| 2 Promote |  |  |  |
| 3 Full    |  |  |  |
| 4 Fault   |  |  |  |
| 5 Rollback|  |  |  |

## Step 3 — The decision gate
You're watching the canary live. For each signal, state your promote/roll-back rule:

| Signal | Promote if… | Roll back if… |
|--------|-------------|---------------|
| Error rate (5xx)     |  |  |
| P99 latency          |  |  |
| Conversion (business)|  |  |

How would each of these rules become *automated* in a real pipeline (no human watching a graph)?

## Step 4 — Multi-cloud tie-back
This demo runs on one cluster. In one or two sentences: with an Istio multi-primary mesh
spanning EKS (AWS) and GKE (GCP), how does the *same* `VirtualService` weight lever let you
canary *across* clouds? What should the canary split mirror?
