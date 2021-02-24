# Deploy without Helm

The deployment YAML files are found in the `eirini.tgz` asset of the latest [eirini release](https://github.com/cloudfoundry-incubator/eirini-release/releases).

If you require set of deployment YAML files from the latest passing eirini build, you can `git checkout` the master branch of [eirini-release](https://github.com/cloudfoundry-incubator/eirini-release) and generate the files using a script:

```sh
cd <eirini-release-directory>
./scripts/render-templates.sh <system-namespace> <output-directory>
```

## Components

Throughout these deployment YAML files, the eirini components are configured to run in the `cf-system` namespace and to deploy LRPs and Tasks to the `cf-workloads` namespace.
These namespaces should be created prior to applying the deployment YAML.

### Core Components

The core eirini components consist of:

- eirini-api (the REST interface that CloudController uses to communicate with Eirini)
- instance-env-injector (a mutating webhook that injects the `CF_INSTANCE_INDEX` env variable into LRP pods)
- task-reporter (calls back to CloudController on the status of completed tasks)
- event-reporter (notifies CloudController of LRP crashes).
  This is found in the events directory.

### Optional Components

The eirini interface is currently moving from using a REST API to a more k8s native approach with CRDs.
The new component replacing _eirini-api_ is _eirini-controller_, found in `core/controller-deployment.yml`.
This is currently experimental.

We also ship a set of components which have been replaced in cf-for-k8s, but are still used in other CF on k8s packages:

- metrics-collector (periodically emits application CPU, memory and disk usage metrics to loggregator)
- route-collector (sends notifications of current, new and removed routes to the go-router via NATS)

## Workloads

The `workloads` directory contains minimal RBAC configuration required in the workloads namespace.
It provides a Service Account and associated Pod Security Policy for running LRPs.
It also gives appropriate role permissions to eirini components that need to interact with resources in the workloads namespace.

## Configuration

### Config Maps

Components are configured using the various `*-configmap.yml` files provided:

| Component         | Configmap YAML                            |
| ----------------- | ----------------------------------------- |
| Eirini API        | `core/api-configmap.yml`                  |
| Task Reporter     | `core/task-reporter-configmap.yml`        |
| Event Reporter    | `events/event-reporter-configmap.yml`     |
| CRD Controller    | `core/controller-configmap.yml`           |
| Metrics Collector | `metrics/metrics-collector-configmap.yml` |
| Route Collector   | `routes/route-collector-configmap.yml`    |

Each configmap is documented describing the options.
Where a certain configuration requires changes to other file, this is noted there.

### Secrets

Eirini depends on the following secrets, which must be named and constructed as follows:

- `capi-tls` (optional when `cc_tls_disabled` is set to true in the component's configmap)

  - `tls.crt`: client certificate used for mTLS
  - `tls.key`: key for client certificate
  - `tls.ca`: CA used to validate CAPI's server certificate

- `eirini-certs` (optional when `serve_plaintext` is set to true in the API configmap)

  - `tls.crt`: server certificate
  - `tls.key`: key for server certificate
  - `tls.ca`: CA used to validate client certificates

- `instance-index-env-injector-certs` (mandatory - required by the mutating webhook configuration)

  - `tls.crt`: server certificate
  - `tls.key`: key for server certificate
  - `tls.ca`: CA used to validate injector webhook's server certificate

- `loggregator-certs` (mandatory when deploying metrics-collector)

  - `tls.crt`: client certificate used for mTLS
  - `tls.key`: key for client certificate
  - `tls.ca`: CA used to validate loggregator's server certificate

- `nats-secret` (mandatory when deploying route-collector)

  - `nats-password`: password to connect to NATS

## Deployment

You can create the Eirini objects using `kubectl`.
First extract the `eirini.tgz` tarball (or run the `render-templates.sh` script).
Then run:

```bash
kubectl apply --recursive=true -f <yaml-directory>
```

Wait for all pods in the `cf-system` namespace to be in the RUNNING state.
That's it!
