#!/bin/bash

set -e
set -o pipefail

gen_openssl_conf_ip(){
cat >> ssl_conf << EOF
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

gen_openssl_conf(){
cat >> ssl_conf << EOF
 [ req ]
 distinguished_name     = req_distinguished_name
 prompt                 = no

 [ req_distinguished_name ]
 O                      = Local Secure Registry for Kubernetes
 CN                     = $REGISTRY
 emailAddress           = eirini@cloudfoundry.org
EOF
}

mkdir certs

kubectl delete secret registry-cert || true

if [[ $REGISTRY =~ [0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4} ]]; then
	echo "generating ip based CA"
  gen_openssl_conf_ip
else
	gen_openssl_conf
fi

openssl req -config /ssl_conf -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key -x509 -days 265 -out certs/ca.crt

kubectl create secret generic registry-cert --from-file=./certs/ca.crt --from-file=./certs/domain.key
