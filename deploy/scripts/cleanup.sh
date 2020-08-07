#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

kubectl delete mutatingwebhookconfigurations eirini-x-mutating-hook
cat "$PROJECT_ROOT"/deploy/**/*.yml | kubectl delete -f -
