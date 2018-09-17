#!/bin/bash

get_cert(){
  kubectl get secret registry-cert \
  -o go-template --template '{{(index .data "ca.crt")}}'
}

if get_cert; then
  mkdir --parents "/workspace/docker/certs.d/$REGISTRY/"
  echo "copying certs"
  get_cert | base64 -d > "/workspace/docker/certs.d/$REGISTRY/ca.crt"
  echo "Sucessfully copied certs"
else
	echo "cert not found"
	exit 1
fi
