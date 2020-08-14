#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cat "$PROJECT_ROOT"/deploy/**/*.yml | kubectl delete -f -
