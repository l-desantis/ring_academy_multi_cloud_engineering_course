# Canary Deployment with Istio Traffic Splitting

## Context
You just shipped `v2` of `payment-service` (a refactored checkout). A full rollout is
too risky. Your task: use Istio to expose `v2` to a slice of live traffic, watch the
signals, then promote it — or kill it — without ever redeploying `v1`.

> **Demo honesty note:** the manifests use Istio's public `helloworld` v1/v2 sample
> images so the pods actually start and return their version. Keep thinking
> "payment-service" — the mechanics are identical. The only thing that matters is the
> **traffic weight**, and that is real.

## Stack
Kubernetes + Istio (`VirtualService` / `DestinationRule`) on a local `kind` cluster.

---

## Fast setup — do this BEFORE class (~10 min)
Needs Docker + [`kind`](https://kind.sigs.k8s.io/) + [`istioctl`](https://istio.io/latest/docs/setup/getting-started/#download). All three are single-binary installs.

```bash
# 1. Local cluster
kind create cluster --name canary-demo

# 2. Istio (demo profile = everything you need)
istioctl install --set profile=demo -y

# 3. Auto-inject sidecars into the default namespace
kubectl label namespace default istio-injection=enabled --overwrite

# 4. Apply the baseline (everything EXCEPT the virtual service)
kubectl apply -f codebase/deploy.yaml
kubectl apply -f codebase/destination-rule.yaml

# 5. Wait until both versions are Running (2/2 = app + sidecar)
kubectl get pods -w
```

**No time to set up?** You can still complete the worksheet by reading the manifests.

---

## Your task

The baseline is running, but **no `VirtualService` is applied yet** — so traffic isn't
split. Open `codebase/virtual-service.yaml`: the structure is there, but the two
`weight:` values are blank. You will fill them in, apply, and watch the traffic move.

### 0. Start the traffic generator (side terminal, leave running)
```bash
bash codebase/loadgen.sh
```
You'll see a stream of `Hello version: v1...` / `Hello version: v2...`.

### 1. Phase 1 — Launch the canary (90/10)
Edit `codebase/virtual-service.yaml` so v1 gets the bulk of traffic and v2 gets a small
slice, then apply it:
```bash
kubectl apply -f codebase/virtual-service.yaml
```
Watch the loadgen stream. **What fraction of lines are now v2?** Record it in the worksheet.

> ⚠️ v1 has 3 pods, v2 has 1 — but the split is **NOT** 75/25. Replica count and traffic
> weight are independent. The `VirtualService` decides the split, not the pod count.

### 2. Phase 2 — Promote (50/50)
Change the weights to an even split, re-apply, watch the stream shift. **No redeploy. No pod restart.**

### 3. Phase 3 — Full promotion (100% v2)
Change the weights so v2 takes all traffic, re-apply. The stream becomes all v2. The canary is now the stable version.

### 4. Inject a regression
Simulate a bad release — 50% of v2 calls now return HTTP 500:
```bash
kubectl apply -f codebase/fault-injection.yaml
```
Watch the errors appear in the stream.

### 5. Roll back — instantly
Edit `codebase/virtual-service.yaml` back to 100% v1 (the stable version that was never
torn down) and apply it. The stream returns to clean v1 in **seconds**. That speed is the
entire operational guarantee of canary — and why "weight to 0" beats "redeploy the old version."

---

## Deliverable
Complete `WORKSHEET.md` as you go.

## Teardown
```bash
kind delete cluster --name canary-demo
```
