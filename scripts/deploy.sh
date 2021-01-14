#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"
export NATS_PASSWORD
NATS_PASSWORD="${NATS_PASSWORD:-dummy-nats-password}"

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
  install_nats
  install_eirini
}

generate_secrets() {
  "$SCRIPT_DIR/generate-secrets.sh" "*.${SYSTEM_NAMESPACE}.svc.cluster.local" "$WIREMOCK_KEYSTORE_PASSWORD"
}

install_nats() {
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm upgrade nats \
    --install bitnami/nats \
    --namespace "$SYSTEM_NAMESPACE" \
    --set auth.user="nats" \
    --set auth.password="$NATS_PASSWORD" \
    --wait
}

install_eirini() {
  helm upgrade eirini \
    --install "$ROOT_DIR/helm" \
    --namespace "$SYSTEM_NAMESPACE" \
    --values "$SCRIPT_DIR/assets/value-overrides.yml" \
    --wait

  # Install wiremock to mock the cloud controller
  kubectl apply -f "$SCRIPT_DIR/assets/wiremock.yml"
}

main
