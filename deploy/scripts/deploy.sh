#!/bin/bash

set -euo pipefail

RED=1
GREEN=2
BLUE=4

print_message() {
  message=$1
  colour=$2
  printf "\\r\\033[00;3%sm%s\\033[0m\\n" "$colour" "$message"
}

warning=$(
  cat <<EOF
** WARNING **

This an example script used to create a standalone Eirini deployment.
It is used internally for testing, but is not supported for external use.

EOF
)

print_message "$warning" "$BLUE"

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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

cat "$PROJECT_ROOT"/deploy/**/namespace.yml | kubectl apply -f -

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade nats \
  --install bitnami/nats \
  --namespace eirini-core \
  --set auth.user="nats" \
  --set auth.password="$NATS_PASSWORD" \
  --wait

kubectl apply -f "$PROJECT_ROOT/deploy/core/"
kubectl apply -f "$PROJECT_ROOT/deploy/events/"
kubectl apply -f "$PROJECT_ROOT/deploy/metrics/"
kubectl apply -f "$PROJECT_ROOT/deploy/routes/"
kubectl apply -R -f "$PROJECT_ROOT/deploy/workloads"

# Install wiremock to mock the cloud controller
kubectl apply -f "$PROJECT_ROOT/deploy/testing/cc-wiremock"

pushd "$PROJECT_ROOT/deploy/scripts"
{
  ./generate_eirini_tls.sh "*.eirini-core.svc.cluster.local" "$WIREMOCK_KEYSTORE_PASSWORD"
}
popd

deployments="$(kubectl get deployments \
  --namespace eirini-core \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{ end }}')"

for dep in $deployments; do
  kubectl rollout status deployment "$dep" --namespace eirini-core
done
