# Canary Demo — Instructor Runbook (Solution)

Complete, worked version of the lesson2 lab. Each phase shows the exact weights and the
expected loadgen behaviour. The student fills `codebase/virtual-service.yaml` to reach
each phase; the matching completed manifest is in `manifests/`.

## Setup (recap)
```bash
kind create cluster --name canary-demo
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f ../codebase/deploy.yaml
kubectl apply -f ../codebase/destination-rule.yaml
kubectl get pods -w   # wait for 2/2 on both versions
```
Start traffic: `bash ../codebase/loadgen.sh`

## Phase 1 — Launch 90/10
`kubectl apply -f manifests/vs-90-10.yaml`
Expected: ~1 in 10 lines is `v2`. **Teaching point:** v1=3 pods, v2=1 pod, but the split is
90/10, not 75/25 — weight is independent of replica count.

## Phase 2 — Promote 50/50
`kubectl apply -f manifests/vs-50-50.yaml`
Expected: ~half the stream is v2. No redeploy, no pod restart. **Teaching point:** in a real
pipeline this one-line change is a PR merged to Git and reconciled by Argo CD — reviewable,
audited, `git revert`-able (the GitOps thread).

## Phase 3 — Full 100%
`kubectl apply -f manifests/vs-100.yaml`
Expected: stream becomes all v2. Canary is now stable.

## Phase 4 — Inject regression
`kubectl apply -f manifests/vs-fault.yaml`
Expected: ~50% of v2 calls return HTTP 500 — errors in the stream (red error-rate spike in Kiali/Grafana).

## Phase 5 — Roll back instantly
`kubectl apply -f manifests/vs-rollback.yaml`
Expected: clean v1 within seconds. **Teaching point:** rollback is fast because v1 was never
torn down — that is the whole operational guarantee of canary.

## Decision gate
| Signal | Promote if… | Roll back if… |
|--------|-------------|---------------|
| Error rate (5xx)      | v2 ≤ v1 | v2 > 5% for 2+ min |
| P99 latency           | v2 within ~10% of v1 | v2 P99 > 1000ms for 2+ min |
| Conversion (business) | stable | drops > 5% |
In a mature pipeline these become Prometheus alert rules (`CanaryHighErrorRate`,
`CanaryHighLatency`) that flip the weight automatically — rollback as code, not a human watching a graph.

## Multi-cloud tie-back
With an Istio multi-primary mesh spanning EKS (AWS) and GKE (GCP), the *same* `VirtualService`
weights shift traffic across providers proportionally. The canary should mirror your capacity
split (e.g. 90% AWS / 10% GCP) — so you canary *across* clouds, not just on one.

## Teardown
`kind delete cluster --name canary-demo`
