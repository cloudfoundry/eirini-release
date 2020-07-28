# Deploy without Helm

** Disclaimer ** The tool agnostic deployment of Eirini is still work in progress. Please stay tuned.

## Prerequisites

- Create two namespaces. `eirini-core` will be used to run Eirini and `eirini-workloads` will be used by Eirini to run apps:

```bash
kubectl create namespace eirini-core
kubectl create namespace eirini-workloads
```

- The Eirini API Server needs to be given a key pair and CA. The certificate information should be put in a secret named `eirini-tls` with the following keys:
  - tls.crt
  - tls.key
  - tls.ca
  This secret should be be created in the `eirini-core` namespace. You can use the `deploy/scripts/generate_eirini_tls.sh` script to generate a self signed cert to get you going.

## Deployment

- Now you can create the Eirini ojbects by running the following command from the root directory of this repository:

```bash
cat deploy/**/*.yml | kubectl apply -f -
```

Wait for all pods in the `eirini-core` namespace to be in the RUNNING state. That's it!

## Testing

There are two ways to talk to eirini: The HTTPS API and the CRD API.

### HTTPS

Eirini comes with a NodePort service that exports it to port `30085` on each node. You can create an LRP using the script below:

```bash
tls_crt="$(kubectl get secret -n eirini-core eirini-tls -o json | jq -r '.data["tls.crt"]' | base64 -d)"
tls_key="$(kubectl get secret -n eirini-core eirini-tls -o json | jq -r '.data["tls.key"]' | base64 -d)"
tls_ca="$(kubectl get secret -n eirini-core eirini-tls -o json | jq -r '.data["tls.ca"]' | base64 -d)"
eirini_host="$(kubectl get nodes -o wide | tail -1 | awk '{ print $7 }')"

curl --cacert <(echo "$tls_ca") --key <(echo "$tls_key") --cert <(echo "$tls_crt") -k "https://$eirini_host:30085/apps/testapp" -X PUT -H "Content-Type: application/json" -d '{"guid": "the-app-guid","version": "0.0.0","ports" : [8080],"lifecycle": {"docker_lifecycle": {"image": "busybox","command": ["/bin/sleep", "100"]}},"instances": 1}'
```

After you do that a pod will appear in the `eirini-workloads` namespace.

### CRD

Eirini defines custom resopurces for tasks and LRPs. Here is how to create an LRP resource:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: eirini.cloudfoundry.org/v1
kind: LRP
metadata:
  name: testapp
  namespace: eirini-workloads
spec:
  GUID: "the-app-guid"
  version: "version-1"
  instances: 1
  lastUpdated: "never"
  ports:
  - 8080
  image: "eirini/dorini"
EOF
```

After you do that a pod will appear in the `eirini-workloads` namespace.




