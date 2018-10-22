#!/bin/bash

set -ex

k8s_api() {
    local api_ver="$1"
    shift
    local svcacct=/var/run/secrets/kubernetes.io/serviceaccount
    curl --silent \
        --cacert "${svcacct}/ca.crt" \
        -H "Authorization: bearer $(cat "${svcacct}/token")" \
        "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/${api_ver}/namespaces/$(cat "${svcacct}/namespace")/${1#/}"
}

json_get() {
  local filter="$1"

  python -c "import sys, json; print(json.load(sys.stdin)${filter})"
}

main() {
  api_ip="$(k8s_api "api/v1" "/services/cc-uploader-cc-uploader" | json_get [\'spec\'][\'clusterIP\'])"
  cp /configs/opi.yml /output/opi.yml
  goml set -f /output/opi.yml -p opi.cc_uploader_ip -v "$api_ip"
}

main
