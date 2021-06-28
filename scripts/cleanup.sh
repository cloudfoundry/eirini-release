#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SYSTEM_NAMESPACE=eirini-core

source "$SCRIPT_DIR/helpers/print.sh"

delete_eirini() {
  helm --namespace "$SYSTEM_NAMESPACE" delete eirini || true
  helm --namespace "$SYSTEM_NAMESPACE" delete nats || true
  helm --namespace "$SYSTEM_NAMESPACE" delete prometheus || true
  kubectl delete -f "$SCRIPT_DIR/assets/wiremock.yml" || true
  kubectl delete namespace "$SYSTEM_NAMESPACE" --wait || true
}

main() {
  print_disclaimer
  delete_eirini
}

main
