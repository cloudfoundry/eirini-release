#!/bin/bash

set -e
set -o pipefail

readonly CERTS_DIR="certs"

main() {
    generate-openssl-conf
    create-certs
    create-secret
}

generate-openssl-conf() {
    if [[ $REGISTRY =~ ^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$ ]]; then
        echo "Generating ip based CA"
        gen-openssl-conf-ip
    else
        echo "Generating host based CA"
        gen-openssl-conf
    fi
}

gen-openssl-conf-ip(){
    cat >> ssl.conf << EOF
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no
x509_extensions        = v3_ca

[ req_distinguished_name ]
O                      = Local Secure Registry for Kubernetes
CN                     = $REGISTRY
emailAddress           = eirini@cloudfoundry.org

[ v3_ca ]
subjectAltName = IP:$REGISTRY
EOF
}

gen-openssl-conf(){
    cat >> ssl.conf << EOF
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
O                      = Local Secure Registry for Kubernetes
CN                     = $REGISTRY
emailAddress           = eirini@cloudfoundry.org
EOF
}

create-certs() {
    mkdir certs
    openssl req -config /ssl.conf \
        -newkey rsa:4096 \
        -nodes \
        -sha256 \
        -x509 \
        -days 265 \
        -keyout $CERTS_DIR/tls.key \
        -out $CERTS_DIR/tls.crt
}

create-secret() {
    kubectl delete secret private-registry-cert || true

    kubectl create secret generic private-registry-cert \
        --from-file=$CERTS_DIR/tls.crt \
        --from-file=$CERTS_DIR/tls.key
}

main
