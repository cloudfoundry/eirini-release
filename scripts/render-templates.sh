#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RENDER_DIR=$(mktemp -d)
trap "rm -r $RENDER_DIR" EXIT

SYSTEM_NAMESPACE=$1
OUTPUT_DIR=$2

shift 2

helm template eirini \
  "$PROJECT_ROOT/helm/" \
  --namespace "$SYSTEM_NAMESPACE" \
  --output-dir="$RENDER_DIR" \
  $@

mv "$RENDER_DIR/eirini/templates" "$OUTPUT_DIR"
