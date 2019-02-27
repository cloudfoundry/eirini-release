#!/bin/bash

readonly REGISTRY_CERTS_DIR="/workspace/docker/certs.d/$REGISTRY/"

get-cert(){
    kubectl get secret private-registry-cert \
      --namespace "${SCF_NAMESPACE}" \
      --output go-template \
      --template '{{(index .data "tls.crt")}}'
}

copy-cert() {
    mkdir --parents "$REGISTRY_CERTS_DIR"
    get-cert | base64 -d > "$REGISTRY_CERTS_DIR/ca.crt"

    echo "Sucessfully copied certs"
}

main(){
  while true; do
    if get-cert; then
        copy-cert
    else
        echo "Nothing to do"
    fi
    sleep 30
  done
}

main
