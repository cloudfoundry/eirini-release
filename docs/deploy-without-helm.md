# Deploy without Helm

**Disclaimer** The tool agnostic deployment of Eirini is still work in progress. Please stay tuned. The deployment YAML is found in the [deploy](../deploy) directory of this release repo.

## Core components

The core eirini components include:

- eirini-api (the REST interface that CloudController uses to communicate with Eirini)
- eirini-controller (CRD k8s controller watching LRP and Task resources)
- instance-env-injector (a mutating webhook that injects the `CF_INSTANCE_INDEX` env variable to app pods)

Throughout these deployment YAML files, the core components are configured to
run in the `eirini-core` namespace and to deploy LRPs and Tasks to the
`eirini-workloads` namespace. The core namespace is created in the
[core/namespace.yml](../deploy/core/namespace.yml) file.

### Configuration

#### Config Maps

Eirini API and controller configuration mainly happens through the [api config map](../deploy/core/api-configmap.yml). Instance Injector configuration is [here](../deploy/core/instance-index-env-injector-configmap.yml).

For API and controller, you can set the following:

- `app_namespace`: namespace in which to create workloads (LRPs and Tasks).
  Can be left blank if deploying to multiple workload namespaces.

- `tls_port`: local port for the REST API server when serving TLS.

- `plaintext_port`: local port for the REST API server when serving plain HTTP.

- `cc_tls_disabled`: set to true when the CloudController does not use TLS (i.e. transport security handled by Istio)

- `disk_limit_mb`: defaults to 2048 if not set, and provides a limit to the app container disk size when not passed by the Cloud Controller

- `application_service_account`: name of service account used to run LRPs and Tasks. See [here](#lrps-and-tasks) for required permissions

- `allow_run_image_as_root`: ***insecure*** allow docker images to run as the privileged user

- `unsafe_allow_automount_service_account_token`: ***insecure*** mount the service account token for the kubenetes API in each LRP / Task pod. Required for cf-for-k8s on Kind.

- `serve_plaintext`: set to true to disable TLS for the REST API. `plaintext_port` must be set. Used when TLS provided by Istio.

When using eirini for staging buildpack apps, rather than kpack, the following are required:

- `staging_service_account`: name of service account used to run staging tasks. See [here](#lrps-and-tasks) for required permissions

- `registry_address`: set the address of the private registry used to store staged app images

- `registry_secret_name`: the name of the secret containing the private docker registry's credentials. Must be of type `kubernetes.io/dockerconfigjson`

- `eirini_address`: the eirini api internal URI, used by the stager to communicate with eirini

- `downloader_image`: set the staging downloader image

- `uploader_image`: set the staging uploader image

- `executor_image`: set the staging executor image

For the Instance Index Injector, you will probably only need to override the service namespace, if using a namespace other than eirini-core for the eirini components:

- `service_namespace`: set the namespace for the injector k8s service

#### Secrets

Eirini depends on the following secrets, which must be named and constructed as follows:

- `capi-tls` (optional, when `cc_tls_disabled` is set to true)
  * `tls.crt`: client certificate used for mTLS
  * `tls.key`: key for client certificate
  * `ca.crt`: CA used to validate CAPI's server certificate

- `eirini-certs` (optional, when `serve_plaintext` is set to true)
  * `tls.crt`: server certificate
  * `tls.key`: key for server certificate
  * `ca.crt`: CA used to validate client certificates

#### Service Accounts

##### LRPs and Tasks

A service account is required with permissions to run applications in the workloads namespace(s).A minimal example is given in the [workloads directory](../deploy/workloads/app-rbac.yml).

The name must match that given in the config map (see above).

##### Staging (optional)

If using eirini to stage buildpack apps, rather than kpack, a service account is required with permissions to stage applications in the workloads namespace(s). A minimal example is given in the [workloads directory](../deploy/workloads/staging-rbac.yml).

The name must match that given in the config map (see above).

### Deployment

Now you can create the Eirini objects by running the following command from the root directory of this repository:

```bash
kubectl apply --recursive=true -f deploy/core/
```

Wait for all pods in the `eirini-core` namespace to be in the RUNNING state. That's it!

For a fuller example, see [deploy.sh](../deploy/scripts/deploy.sh) which also sets up some external access.
