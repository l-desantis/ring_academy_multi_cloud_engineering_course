#!/usr/bin/env bash
# Traffic generator — leave this running in a side terminal while you shift weights.
# Each line prints which version served the request. The visible v1:v2 ratio IS the canary.
# Stop with Ctrl-C (the pod auto-deletes via --rm).
set -euo pipefail

kubectl run loadgen --image=curlimages/curl -i --rm --restart=Never -- \
  sh -c 'while true; do curl -s payment-service:5000/hello; echo; sleep 0.2; done'
