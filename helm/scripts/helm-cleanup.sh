#!/bin/bash

set -eu

EIRINI_RELEASE="$(cd "$(dirname "$0")/../.." && pwd)"

helm delete --purge nats || true
helm delete --purge eirini || true

workloadsNS="$(goml get --file $EIRINI_RELEASE/helm/eirini/values.yaml --prop opi.namespace)"

echo -n "waiting for $workloadsNS to disappear "
while kubectl get ns "$workloadsNS" &>/dev/null; do
  echo -n .
  sleep 1
done
echo " gone"