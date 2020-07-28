#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cat "$PROJECT_ROOT"/deploy/**/namespace.yml | kubectl apply -f -

pushd "$PROJECT_ROOT/deploy/scripts"
{
  ./generate_eirini_tls.sh
}
popd

cat "$PROJECT_ROOT"/deploy/**/*.yml | kubectl apply -f -
