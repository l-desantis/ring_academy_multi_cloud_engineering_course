#!/usr/bin/env bash
# Deletes the bucket directly on the "cloud" (LocalStack), bypassing Crossplane,
# to simulate someone "just fixing one thing" in the console. Run from the HOST
# (not inside the Kind cluster).
# Requires: uv tool install awscli-local  (or: pipx install awscli-local)

set -euo pipefail

awslocal s3 rb s3://my-multicloud-bucket

echo
echo "Cloud-side bucket list after deletion (should be empty):"
awslocal s3 ls
