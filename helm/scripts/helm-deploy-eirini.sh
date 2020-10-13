#!/bin/bash

set -euo pipefail

EIRINI_RELEASE="$(cd "$(dirname "$0")/../.." && pwd)"
CI_DIR="$EIRINI_RELEASE/../eirini-ci"
NATS_PASSWORD="dummy-nats-password"

main() {
  install_tiller

  values_file=$(mktemp)
  create_values_file $values_file
  helm-install $values_file
  rm $values_file

  install-nats
  install-wiremock
  create-test-secret
  wait-for-deployments
}

install_tiller() {
  kubectl apply -f "$CI_DIR/k8s-specs/tiller-service-account.yml"
  kubectl apply -f "$CI_DIR/k8s-specs/restricted-psp.yaml"
  helm init --service-account tiller --upgrade --wait
  helm repo add bitnami https://charts.bitnami.com/bitnami
}

create_values_file() {
  local file=$1
  cp "$EIRINI_RELEASE/helm/scripts/assets/helm-values-template.yml" "$file"
  cluster_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
  goml set --prop kube.external_ips.+ --value "$cluster_ip" --file "$file"
  if [ "${USE_MULTI_NAMESPACE:-false}" == "true" ]; then
    goml set --prop opi.enable_multi_namespace_support --value "true" --file "$file"
  else
    goml set --prop opi.enable_multi_namespace_support --value "false" --file "$file"
  fi
}

install-nats() {
  helm upgrade nats \
    --install bitnami/nats \
    --namespace cf \
    --set auth.user="nats" \
    --set auth.password="$NATS_PASSWORD"
}

install-wiremock() {
  kubectl apply -n cf -f "$EIRINI_RELEASE/helm/scripts/assets/wiremock.yml"
}

create-test-secret() {
  if kubectl -n cf get secret eirini-certs >/dev/null 2>&1; then
    echo "Secret eirini-certs already exists. Skipping cert generation..."
    return
  fi

  local nats_password_b64 cert key secrets_file
  nats_password_b64="$(echo -n "$NATS_PASSWORD" | base64)"
  openssl req -x509 -newkey rsa:4096 -keyout test.key -out test.cert -nodes -subj '/CN=localhost' -addext "subjectAltName = DNS:eirini-opi.cf.svc.cluster.local" -days 365
  cert=$(base64 -w0 <test.cert)
  key=$(base64 -w0 <test.key)
  rm test.*

  secrets_file=$(mktemp)
  cat <<EOF >"$secrets_file"
apiVersion: v1
kind: Secret
metadata:
  name: eirini-certs
type: Opaque
data:
  tls.crt: "$cert"
  ca.crt: "$cert"
  tls.key: "$key"
  nats-password: "$nats_password_b64"
EOF

  kubectl apply -n cf -f "$secrets_file"
}

helm-install() {
  helm upgrade --install eirini \
    "$EIRINI_RELEASE/helm/eirini" \
    --namespace cf \
    --values $1
}

wait-for-deployments() {
  local deployments
  deployments="$(kubectl get deployments \
    --namespace cf \
    --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{ end }}')"

  for dep in $deployments; do
    kubectl rollout status deployment "$dep" --namespace cf
  done
}

main
