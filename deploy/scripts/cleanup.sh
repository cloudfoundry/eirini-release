#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

kubectl delete --recursive=true -f "$PROJECT_ROOT"/deploy
