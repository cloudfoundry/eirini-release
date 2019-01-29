# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini).

**NOTE**: This is an **_experimental_** release and is still considered _work in progress_.

## Deploy Eirini with Containerized Cloud Foundry (SCF)

If you want to deploy a full containerized CF (`SCF`) with `Eirini` you should follow the [SCF + Eirini documentation](./scf/README.md)

## Deploy Standalone Eirini

If you want to deploy _only_ Eirini on a Kube cluster, you can follow the instruction below:

### Prerequisites

Beside a Kubernetes cluster you should have:

[helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)

### Deploy

1. Copy the Kubernetes config file to `helm/eirini/configs/` directory as `kube.yaml` (name is important)

    ```console
    kubectl config view --flatten > helm/eirini/configs/kube.yaml
    ```

1. Create `helm/eirini/configs/opi.yaml` using the following template:

    ```yaml
    opi:
      kube_config: "/workspace/jobs/opi/config/kube.conf"
      kube_namespace: "<target-kubernetes-namespace>"
      kube_endpoint: "<target-kubernetes-api-endpoint>"
      nats_password: "<cf-nats-password>"
      nats_ip: "<cf-nats-ip>"
      api_endpoint: "<cf-api-endpoint>"
      cf_username: "<cf-username>"
      cf_password: "<cf-password>"
      external_eirini_address: "<eirini-registry-host>:<port>"
      cc_uploader_ip: "<cc-uploader-ip>"
      cc_certs_secret_name: "<certs-secret-name>"
      eirini_address: "<eirini-opi-host>:<port>"
      skip_ssl_validation: <true | false>
      insecure_skip_verify: <true | false>
    ```

    - `kube_namespace`: Namespace where CF apps are going to be deployed by OPI
    - `nats_password and nats_ip`: Nats information can be found in [cf-deployment](https://github.com/cloudfoundry/cf-deployment) manifest and `deployment-vars.yml`
    - `external_eirini_address`: Host:Port for Eirini registry, usually on port `8080`
    - `eirini_address`: Host:Port for Eirini opi, usually on port `8085`
1. Copy certificate files in `helm/eirini/certs/`:
    - `cc_cert`: Certificate of the `cc-uploader`
    - `cc_ca`: Certificate authority for the `cc-uploader`
    - `cc_priv`: TLS private key for the `cc-uploader`

    _**NOTE:**_ If you are using [cf-deployment](https://github.com/cloudfoundry/cf-deployment) you can get the certificates from the generated `vars.yml`. You can get the values using the following commands:

    ```console
    bosh int <path-to-vars-yaml> --path /cc_bridge_cc_uploader/certificate >cc_cert
    bosh int <path-to-vars-yaml> --path /cc_bridge_cc_uploader/ca >cc_ca
    bosh int <path-to-vars-yaml> --path /cc_bridge_cc_uploader/private_key >cc_priv
    ```

1. Install the chart using the following `helm` command:

    ```console
    helm install --set-string ingress.opi.host="eirini-opi.<kube-ingress-endpoint>",ingress.registry.host="eirini-registry.<kube-ingress-endpoint>" ./helm/eirini
    ```

That's it :)

### Enable logging

To enable logging with `log-cache` you need to deploy oratos on your kubernetes cluster. To do this follow the instructions on the `eirini` branch on [this repo](https://github.com/gdankov/oratos-deployment/tree/eirini). To get the logs of your app use the [log-cache cli](https://github.com/cloudfoundry/log-cache-cli#stand-alone-cli) with the following format

```console
log-cache tail <app_guid>
```

You can also use `cf` directly by installing the [log-cache plugin](https://github.com/cloudfoundry/log-cache-cli#installing-plugin) and using

```console
cf tail <app_name>
```

You can get the _<app_guid>_ by running `cf app <app_name> --guid`

**Note**: before calling any of `log-cache` or `cf tail` you *must* export the `LOG_CACHE_ADDR` environment variable as specified [here](https://github.com/gdankov/oratos-deployment/tree/eirini#accessing-logs-via-logcache).

_Example calls_:

```console
log-cache tail 05f501f4-569f-429d-a3f5-bedc15b923b5
cf tail dora
```

### Run Smoke Tests

1. Clone [CF-Smoke-Tests](https://github.com/cloudfoundry/cf-smoke-tests)
1. Setup the smoke tests by following the [test-setup](https://github.com/cloudfoundry/cf-smoke-tests#test-setup) provided in the cf-smoke-tests readme.
1. Navigate to the `smoke-tests` directory and run the smoke tests as follows:

  ```console
  bin/test -r -skip="/logging/loggregator_test.go" --regexScansFilePath=true
  ```

  This will disable the `logging` tests, as `logging` is currently not supported by `eirini`.

## Contributing

1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository

## Helpful Resources
* [Eirini Continuous Integration Pipelines](https://ci.flintstone.cf.cloud.ibm.com/teams/eirini/pipelines/ci)
* [scf-builder Pipeline](https://ci.flintstone.cf.cloud.ibm.com/teams/eirini/pipelines/scf-builder)
