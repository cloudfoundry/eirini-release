#!/bin/bash

echo "Will now generate tls.ca tls.crt and tls.key files"

mkdir -p keys
trap 'rm -rf keys' EXIT

pushd keys
{
  opiExternalIp=$(kubectl get svc -n eirini-core eirini-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
  openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -nodes -subj '/CN=localhost' -addext "subjectAltName = IP:${opiExternalIp}" -days 365

  echo "Creating the secret in your kubernetes cluster"
  kubectl create secret -n eirini-core generic eirini-tls --from-file=tls.crt=./tls.crt --from-file=tls.ca=./tls.crt --from-file=tls.key=./tls.key

  echo "Done!"
}
popd
