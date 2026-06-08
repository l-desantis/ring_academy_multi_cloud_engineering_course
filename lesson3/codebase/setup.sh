#!/usr/bin/env bash
# Lesson 3 pre-lab setup: Kind + LocalStack + Crossplane core + provider-aws-s3 + creds secret.
# Run ONCE before the lab. Re-runs will warn on existing resources but won't break.
# After this finishes, you still need to:
#   1. Fill the endpoint URL gap in codebase/providerconfig.yaml
#   2. kubectl apply -f codebase/providerconfig.yaml
#   3. kubectl apply -f codebase/runtimeconfig.yaml
#   4. kubectl apply -f codebase/bucket.yaml
# See EXERCISE.md.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# 1. Local Kubernetes cluster
kind create cluster --name xplane-demo

# 2. LocalStack (S3 emulation) on the host's :4566
docker run -d --name localstack -p 4566:4566 localstack/localstack

# 3. Crossplane core via Helm
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane \
  -n crossplane-system --create-namespace --wait

# 4. Install the S3 provider (this is what adds `kind: Bucket`)
kubectl apply -f "$HERE/provider.yaml"
kubectl wait --for=condition=Healthy provider/provider-aws-s3 --timeout=300s

# 5. Credentials secret (throwaway LocalStack creds — see comment in the file)
kubectl apply -f "$HERE/aws-creds-secret.yaml"

echo
echo "Setup complete. Next:"
echo "  1. Fill the endpoint URL gap in lesson3/codebase/providerconfig.yaml"
echo "  2. kubectl apply -f lesson3/codebase/providerconfig.yaml"
echo "  3. kubectl apply -f lesson3/codebase/runtimeconfig.yaml"
echo "  4. kubectl apply -f lesson3/codebase/bucket.yaml"
