#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

kubectl delete mutatingwebhookconfigurations eirini-x-mutating-hook
kubectl delete --recursive=true -f "$PROJECT_ROOT"/deploy
