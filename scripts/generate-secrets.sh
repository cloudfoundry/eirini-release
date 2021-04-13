#!/bin/bash

set -eu

echo "Will now generate tls.ca tls.crt and tls.key files"

mkdir -p keys
trap 'rm -rf keys' EXIT

otherDNS=$1
keystore_password=$2

pushd keys
{
  kubectl create namespace eirini-core || true

  openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -nodes -subj '/CN=localhost' -addext "subjectAltName = DNS:$otherDNS, DNS:$otherDNS.cluster.local" -days 365

  for secret_name in eirini-certs loggregator-certs capi-tls instance-index-env-injector-certs resource-validator-certs; do
    if kubectl -n eirini-core get secret "$secret_name" >/dev/null 2>&1; then
      kubectl delete secret -n eirini-core "$secret_name"
    fi
    echo "Creating the $secret_name secret in your kubernetes cluster"
    kubectl create secret -n eirini-core generic "$secret_name" --from-file=tls.crt=./tls.crt --from-file=tls.ca=./tls.crt --from-file=tls.key=./tls.key
  done

  if kubectl -n eirini-core get secret wiremock-keystore >/dev/null 2>&1; then
    kubectl delete secret -n eirini-core wiremock-keystore
  fi
  pem_file=$(mktemp)
  keystore_file=$(mktemp)
  cat ./tls.key >"$pem_file"
  cat ./tls.crt >>"$pem_file"
  openssl pkcs12 -export -in "$pem_file" -out "$keystore_file" -password "pass:$keystore_password"

  kubectl create secret -n eirini-core generic wiremock-keystore --from-file=keystore.pkcs12="$keystore_file" --from-literal=ks.pass="$keystore_password"
  rm "$pem_file"
  rm "$keystore_file"

  echo "Done!"
}
popd
