#!/bin/bash

get-cert(){
    kubectl get secret private-registry-cert \
      --output go-template \
      --template '{{(index .data "tls.crt")}}'
}

copy-cert() {
    local cert_dir="/workspace/docker/certs.d/$REGISTRY/"
    mkdir --parents "$cert_dir"
    get-cert | base64 -d > "$cert_dir/ca.crt"

    echo "Sucessfully copied certs"
}

if get-cert; then
    copy-cert
else
    echo "Cert not found"
    exit 1
fi
