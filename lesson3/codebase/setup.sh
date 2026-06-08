#!/usr/bin/env bash
# Lesson 3 pre-lab setup: Kind + LocalStack + Crossplane core + provider-aws-s3 + creds secret.
# Run ONCE before the lab. Re-runs will warn on existing resources but won't break.
# After this finishes, you still need to:
#   1. kubectl apply -f codebase/providerconfig.yaml
#   2. kubectl apply -f codebase/runtimeconfig.yaml
#   3. kubectl patch provider provider-aws-s3 --type=merge -p '{"spec":{"runtimeConfigRef":{"name":"fast-poll"}}}'
#   4. kubectl apply -f codebase/bucket.yaml
# See EXERCISE.md.
#
# PREREQUISITE: LocalStack v4+ requires a free auth token.
#   Sign up at https://app.localstack.cloud, then:
#   export LOCALSTACK_AUTH_TOKEN=<your-token>

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# Validate LocalStack token is set before we even start
if [[ -z "${LOCALSTACK_AUTH_TOKEN:-}" ]]; then
  echo "ERROR: LOCALSTACK_AUTH_TOKEN is not set."
  echo "  LocalStack v4+ requires a free auth token."
  echo "  Sign up at https://app.localstack.cloud, then:"
  echo "    export LOCALSTACK_AUTH_TOKEN=<your-token>"
  exit 1
fi

# 1. Local Kubernetes cluster
kind create cluster --name xplane-demo

# 2. LocalStack (S3 emulation) on the host's :4566
docker run -d --name localstack \
  -e LOCALSTACK_AUTH_TOKEN="${LOCALSTACK_AUTH_TOKEN}" \
  -p 4566:4566 localstack/localstack

# Wait for LocalStack to be healthy before continuing
echo "Waiting for LocalStack to be ready..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:4566/_localstack/health | grep -q '"s3"'; then
    echo "LocalStack ready."
    break
  fi
  sleep 2
done

# 3. Connect LocalStack to the Kind network so pods can reach it directly
# This also gives LocalStack a stable IP on the cluster network.
docker network connect kind localstack

LOCALSTACK_KIND_IP=$(docker inspect localstack \
  --format '{{range .NetworkSettings.Networks}}{{if eq (printf "%s" .NetworkID | head -c 0) ""}}{{.IPAddress}}{{end}}{{end}}' 2>/dev/null || \
  docker inspect localstack --format '{{(index .NetworkSettings.Networks "kind").IPAddress}}')

echo "LocalStack IP on Kind network: ${LOCALSTACK_KIND_IP}"

# 4. Crossplane core via Helm
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane \
  -n crossplane-system --create-namespace --wait

# 5. Patch CoreDNS so that *.s3.localhost.localstack.cloud resolves to LocalStack
# inside the cluster. This enables S3 virtual-hosted-style URLs to work correctly.
COREDNS_CM=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')
HOSTS_BLOCK="    hosts {\n       ${LOCALSTACK_KIND_IP} s3.localhost.localstack.cloud\n       fallthrough\n    }\n    rewrite name regex (.*)\\\\.s3\\\\.localhost\\\\.localstack\\\\.cloud s3.localhost.localstack.cloud"

kubectl patch configmap coredns -n kube-system --type merge -p \
  "{\"data\":{\"Corefile\":\".:53 {\n    errors\n    health {\n       lameduck 5s\n    }\n    ready\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n       pods insecure\n       fallthrough in-addr.arpa ip6.arpa\n       ttl 30\n    }\n${HOSTS_BLOCK}\n    prometheus :9153\n    forward . /etc/resolv.conf {\n       max_concurrent 1000\n    }\n    cache 30 {\n       disable success cluster.local\n       disable denial cluster.local\n    }\n    loop\n    reload\n    loadbalance\n}\n\"}}"

kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system --timeout=60s

# 6. Install the S3 provider (this is what adds `kind: Bucket`)
kubectl apply -f "$HERE/provider.yaml"
kubectl wait --for=condition=Healthy provider/provider-aws-s3 --timeout=300s

# 7. Credentials secret (throwaway LocalStack creds — see comment in the file)
kubectl apply -f "$HERE/aws-creds-secret.yaml"

echo
echo "Setup complete. Next:"
echo "  1. kubectl apply -f lesson3/codebase/providerconfig.yaml"
echo "  2. kubectl apply -f lesson3/codebase/runtimeconfig.yaml"
echo "  3. kubectl patch provider provider-aws-s3 --type=merge -p '{\"spec\":{\"runtimeConfigRef\":{\"name\":\"fast-poll\"}}}'"
echo "  4. kubectl apply -f lesson3/codebase/bucket.yaml"
