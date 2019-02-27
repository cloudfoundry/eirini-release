#!/bin/bash

set -xeuo pipefail
IFS=$'\n\t'

scf_secrets="$(kubectl get secret "$SECRET_NAME" --namespace="$SCF_NAMESPACE" --export -o yaml | grep -E 'cc-.*|internal-ca-.*')"

cat <<EOT >> secret.yml
---
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
type: Opaque
data:
${scf_secrets}
EOT

cat secret.yml

kubectl apply -f secret.yml --namespace "$OPI_NAMESPACE"
