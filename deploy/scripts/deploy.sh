#!/bin/bash

set -euo pipefail

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
