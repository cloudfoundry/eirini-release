#!/bin/bash

set -euo pipefail

EIRINI_RELEASE="$(cd "$(dirname "$0")/../.." && pwd)"
CI_DIR="$EIRINI_RELEASE/../eirini-ci"
NATS_PASSWORD="dummy-nats-password"
export WIREMOCK_KEYSTORE_PASSWORD
WIREMOCK_KEYSTORE_PASSWORD=${WIREMOCK_KEYSTORE_PASSWORD:-""}

main() {
  install-nats
  create-test-secret

  values_file=$(mktemp)
  create_values_file $values_file
  install-eirini $values_file
  rm $values_file

  install-wiremock
  wait-for-deployments
}

create_values_file() {
  local file=$1
  cp "$EIRINI_RELEASE/helm/scripts/assets/helm-values-template.yml" "$file"
}

install-nats() {
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm upgrade nats \
    --install bitnami/nats \
    --version "4.5.8" \
    --namespace cf \
    --set auth.user="nats" \
    --set auth.password="$NATS_PASSWORD" \
    --wait
}

install-wiremock() {
  kubectl apply -n cf -f "$EIRINI_RELEASE/helm/scripts/assets/wiremock.yml"
}

create-test-secret() {
  local cert key secrets_file

  openssl req -x509 -newkey rsa:4096 -keyout test.key -out test.cert -nodes -subj '/CN=localhost' -addext "subjectAltName = DNS:*.cf.svc.cluster.local" -days 365
  cert=$(base64 -w0 <test.cert)
  key=$(base64 -w0 <test.key)

  secrets_file=$(mktemp)
  cat <<EOF >"$secrets_file"
apiVersion: v1
kind: Secret
metadata:
  name: eirini-certs
type: Opaque
data:
  tls.crt: "$cert"
  ca.crt: "$cert"
  tls.key: "$key"
---
apiVersion: v1
kind: Secret
metadata:
  name: capi-tls
type: Opaque
data:
  tls.crt: "$cert"
  ca.crt: "$cert"
  tls.key: "$key"
EOF

  kubectl apply -n cf -f "$secrets_file"

  pem_file=$(mktemp)
  keystore_file=$(mktemp)
  cat test.key >"$pem_file"
  cat test.cert >>"$pem_file"
  openssl pkcs12 -export -in "$pem_file" -out "$keystore_file" -password "pass:$WIREMOCK_KEYSTORE_PASSWORD"

  kubectl create secret -n cf generic wiremock-keystore --from-file=keystore.pkcs12="$keystore_file" --from-literal=ks.pass="$WIREMOCK_KEYSTORE_PASSWORD"

  kubectl create secret -n cf generic nats-secret --from-literal "nats-password=$NATS_PASSWORD"

  rm test.*
  rm "$pem_file"
  rm "$keystore_file"
}

install-eirini() {
  helm upgrade --install eirini \
    "$EIRINI_RELEASE/helm/eirini" \
    --namespace cf \
    --values $1
}

wait-for-deployments() {
  local deployments
  deployments="$(kubectl get deployments \
    --namespace cf \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{ end }}')"

  for dep in $deployments; do
    kubectl rollout status deployment "$dep" --namespace cf
  done
}

main
