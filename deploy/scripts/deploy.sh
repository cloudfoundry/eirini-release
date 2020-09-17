#!/bin/bash

set -euo pipefail

RED=1
GREEN=2

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

print_message "$warning" "$RED"

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
USE_LOADBALANCED_SERVICE=${USE_LOADBALANCED_SERVICE:-"false"}

export KUBECONFIG
KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}
KUBECONFIG=$(readlink -f "$KUBECONFIG")

export GOOGLE_APPLICATION_CREDENTIALS
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-""}
if [[ -n $GOOGLE_APPLICATION_CREDENTIALS ]]; then
  GOOGLE_APPLICATION_CREDENTIALS=$(readlink -f "$GOOGLE_APPLICATION_CREDENTIALS")
fi

cat "$PROJECT_ROOT"/deploy/**/namespace.yml | kubectl apply -f -

kubectl apply --recursive=true -f "$PROJECT_ROOT"/deploy/core/
kubectl apply --recursive=true -f "$PROJECT_ROOT"/deploy/workloads/

# Install wiremock to mock the cloud controller
kubectl apply -f $PROJECT_ROOT/deploy/testing/cc-wiremock.yml

if [[ ${USE_LOADBALANCED_SERVICE} == "true" ]]; then
  echo "Creating the externally accessible api service using LoadBalancer"
  kubectl apply -f $PROJECT_ROOT/deploy/testing/api-loadbalanced-service.yml
  echo "Waiting until our opi service gets an IP address from the LoadBalancer"
  externalIP=""
  while [ "$externalIP" == "" ]; do
    externalIP=$(kubectl get svc -n eirini-core eirini-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo -n "."
    sleep 1
  done
else
  # Make eirini accessible on a local dev kind cluster
  echo "Creating the externally accessible api service (using externalIPs)"
  externalIP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
  if kubectl -n eirini-core get service eirini-external; then
    echo "Deleting eirini-external service"
    kubectl -n eirini-core delete service eirini-external
  fi
  echo "Creating eirini-external service"
  kubectl expose deployment eirini-api -n eirini-core \
    --type ClusterIP \
    --name eirini-external \
    --external-ip "${externalIP}" \
    --port 443 \
    --target-port 8085
fi

pushd "$PROJECT_ROOT/deploy/scripts"
{
  ./generate_eirini_tls.sh $externalIP
}
popd

for dep in $(ls -1 $PROJECT_ROOT/deploy/core/*-deployment.yml); do
  kubectl rollout status -f $dep
done
