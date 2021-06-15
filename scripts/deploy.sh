#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"

export KUBECONFIG
KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}
KUBECONFIG=$(readlink -f "$KUBECONFIG")

export GOOGLE_APPLICATION_CREDENTIALS
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-""}
if [[ -n $GOOGLE_APPLICATION_CREDENTIALS ]]; then
  GOOGLE_APPLICATION_CREDENTIALS=$(readlink -f "$GOOGLE_APPLICATION_CREDENTIALS")
fi
export WIREMOCK_KEYSTORE_PASSWORD
WIREMOCK_KEYSTORE_PASSWORD=${WIREMOCK_KEYSTORE_PASSWORD:-""}

readonly SYSTEM_NAMESPACE=eirini-core

source "$SCRIPT_DIR/helpers/print.sh"

main() {
  print_disclaimer
  generate_secrets
  install_prometheus
  install_eirini "$@"
}

generate_secrets() {
  "$SCRIPT_DIR/generate-secrets.sh" "*.${SYSTEM_NAMESPACE}.svc" "$WIREMOCK_KEYSTORE_PASSWORD"
}

install_prometheus() {
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm upgrade prometheus \
    --install prometheus-community/prometheus \
    --namespace "$SYSTEM_NAMESPACE" \
    --wait
}

install_eirini() {
  local env_injector_ca_bundle
  env_injector_ca_bundle="$(kubectl get secret -n $SYSTEM_NAMESPACE eirini-instance-index-env-injector-certs -o jsonpath="{.data['tls\.ca']}")"
  helm upgrade eirini \
    --install "$ROOT_DIR/helm" \
    --namespace "$SYSTEM_NAMESPACE" \
    --values "$SCRIPT_DIR/assets/value-overrides.yml" \
    --set "webhook_ca_bundle=$env_injector_ca_bundle" \
    --wait \
    "$@"

  # Install wiremock to mock the cloud controller
  kubectl apply -f "$SCRIPT_DIR/assets/wiremock.yml"
}

main "$@"
