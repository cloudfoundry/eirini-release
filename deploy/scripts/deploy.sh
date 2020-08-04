#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cat "$PROJECT_ROOT"/deploy/**/namespace.yml | kubectl apply -f -

kubectl apply -f deploy/testing/opi-external-service.yml
echo "Waiting until our opi service gets an IP address from the LoadBalancer"
while [ "$(kubectl get svc -n eirini-core eirini-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" == "" ]; do
  echo -n "."
  sleep 1
done

pushd "$PROJECT_ROOT/deploy/scripts"
{
  ./generate_eirini_tls.sh
}
popd

cat "$PROJECT_ROOT"/deploy/**/*.yml | kubectl apply -f -
