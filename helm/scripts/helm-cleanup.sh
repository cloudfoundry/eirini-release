#!/bin/bash

set -eu

EIRINI_RELEASE="$(cd "$(dirname "$0")/../.." && pwd)"

helm delete nats || true
helm delete eirini || true

workloadsNS="$(goml get --file $EIRINI_RELEASE/helm/eirini/values.yaml --prop opi.namespace)"

echo -n "waiting for $workloadsNS to disappear "
while kubectl get ns "$workloadsNS" &>/dev/null; do
  echo -n .
  sleep 1
done
echo " gone"

kubectl -n cf delete secret capi-tls || true
kubectl -n cf delete secret eirini-certs || true
kubectl -n cf delete secret wiremock-keystore || true
kubectl -n cf delete secret nats-secret || true
