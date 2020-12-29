#!/bin/bash

set -eu

echo "Will now generate tls.ca tls.crt and tls.key files"

mkdir -p keys
trap 'rm -rf keys' EXIT

otherDNS=$1
keystore_password=$2

pushd keys
{
  openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -nodes -subj '/CN=localhost' -addext "subjectAltName = DNS:$otherDNS" -days 365

  if ! kubectl -n eirini-core get secret eirini-certs >/dev/null 2>&1; then
    echo "Creating the secret in your kubernetes cluster"
    kubectl create secret -n eirini-core generic eirini-certs --from-file=tls.crt=./tls.crt --from-file=ca.crt=./tls.crt --from-file=tls.key=./tls.key
  fi

  if ! kubectl -n eirini-core get secret loggregator-certs >/dev/null 2>&1; then
    kubectl create secret -n eirini-core generic loggregator-certs --from-file=tls.crt=./tls.crt --from-file=ca.crt=./tls.crt --from-file=tls.key=./tls.key
  fi

  if ! kubectl -n eirini-core get secret capi-tls >/dev/null 2>&1; then
    kubectl create secret -n eirini-core generic capi-tls --from-file=tls.crt=./tls.crt --from-file=ca.crt=./tls.crt --from-file=tls.key=./tls.key
  fi

  if ! kubectl -n eirini-core get secret wiremock-keystore >/dev/null 2>&1; then
    pem_file=$(mktemp)
    keystore_file=$(mktemp)
    cat ./tls.key >"$pem_file"
    cat ./tls.crt >>"$pem_file"
    openssl pkcs12 -export -in "$pem_file" -out "$keystore_file" -password "pass:$keystore_password"
    kubectl create secret -n eirini-core generic wiremock-keystore --from-file=keystore.pkcs12="$keystore_file" --from-literal=ks.pass="$keystore_password"
    rm "$pem_file"
    rm "$keystore_file"
  fi

  echo "Done!"
}
popd
