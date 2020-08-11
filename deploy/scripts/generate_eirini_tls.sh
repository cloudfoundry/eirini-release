#!/bin/bash

set -eu

if kubectl -n eirini-core get secret eirini-certs >/dev/null 2>&1; then
  echo "Secret eirini-certs already exists. Skipping cert generation..."
  exit 0
fi

echo "Will now generate tls.ca tls.crt and tls.key files"

mkdir -p keys
trap 'rm -rf keys' EXIT

externalIP=$1

pushd keys
{
  openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -nodes -subj '/CN=localhost' -addext "subjectAltName = IP:${externalIP}" -days 365

  echo "Creating the secret in your kubernetes cluster"
  kubectl create secret -n eirini-core generic eirini-certs --from-file=tls.crt=./tls.crt --from-file=ca.crt=./tls.crt --from-file=tls.key=./tls.key

  echo "Done!"
}
popd
