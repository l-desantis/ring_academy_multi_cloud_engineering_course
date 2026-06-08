#!/usr/bin/env bash
# Deletes the bucket directly on the "cloud" (LocalStack), bypassing Crossplane,
# to simulate someone "just fixing one thing" in the console. Run from the HOST
# (not inside the Kind cluster) — `localhost:4566` here is LocalStack on your laptop.

set -euo pipefail

aws --endpoint-url http://localhost:4566 s3 rb s3://my-multicloud-bucket

echo
echo "Cloud-side bucket list after deletion (should be empty):"
aws --endpoint-url http://localhost:4566 s3 ls
