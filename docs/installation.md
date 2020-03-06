## Table of contents

* [Prerequisites](#prerequisites)
  * [Minimum cluster requirements](#minimum-cluster-requirements)
* [Installation](#installation)
* [Notes](#notes)
  * [Overriding Eirini Images](#overriding-eirini-images)
  * [CF acceptance tests](#cf-acceptance-tests)
    * [Running CATs against Eirini](#running-cats-against-eirini)
  * [Storage Class](#storage-class)
    * [Using the HostPath Provisioner](#using-the-hostpath-provisioner)
    * [Production Deployment](#production-deployment)
    * [IBMCloud Kubernetes Service (IKS)](#ibmcloud-kubernetes-service-iks)
  * [Certificates](#certificates)

## Prerequisites

* Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
* Install [Metrics server](https://github.com/kubernetes-incubator/metrics-server) in the system namespace
* Install [helm](https://helm.sh/)
* To be able to use the [bits service](https://github.com/cloudfoundry-incubator/bits-service) private registry in your Kubernetes cluster,
you need to have a signed TLS certificate, with a CA that the docker or containerd daemon on the nodes trust, and a CN that is pointing to the bits service.

**Note**: Eirini is currently being tested with HELM > 2.15.2, Kubernetes 1.14, and containerd as the container runtime.

### Minimum cluster requirements

We have validated that the deployment can start with a single-node 4 core 16GB cluster, although the initial startup will be very slow with this setup.
We recommend at least 8 cores and 16GB of RAM for the SCF control plane and at least two additional nodes that you can scale relative to the average consumption
of resource of the applications that you will be deploying.

## Installation

### GKE-specific instructions

Follow instructions [here](./gke.md).

### General instructions

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. For additional information you can take a look at [Storage Class](#storage-class)
1. Create a `values.yaml` based on [this](../values.yaml) template.
1. Make the Eirini helm repository available to helm:

    ```bash
    helm repo add eirini https://cloudfoundry-incubator.github.io/eirini-release
    ```

1. Make the Bits helm repository available to helm:

     ```bash
    helm repo add bits https://cloudfoundry-incubator.github.io/bits-service-release/helm
    ```

1. Install UAA:

    ```bash
    helm install eirini/uaa --namespace uaa --name uaa --values <your-values.yaml>
    ```

1. Export the UAA ca certificate using the following commands:

    ```bash
    SECRET=$(kubectl get pods --namespace uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
    CA_CERT="$(kubectl get secret $SECRET --namespace uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
    ```

1. Export the Registry certificate in the `BITS_TLS_KEY` and `BITS_TLS_CRT` environment variables. (see [Certificates](#Certificates))

1. Install CF:

    ```bash
    helm install eirini/cf --namespace scf --name scf --values <your-values.yaml> --set "secrets.UAA_CA_CERT=${CA_CERT}" --set "bits.secrets.BITS_TLS_KEY=${BITS_TLS_KEY}" --set "bits.secrets.BITS_TLS_CRT=${BITS_TLS_CRT}"
    ```

    **NOTICE**

    The above command will take the default value for `rootfs_version`. In case you want to specify a rootfs_version at deploy time use

    ```bash
    --set "global.rootfs_version=vx.x.x"
    ```

    This will download the mentioned version of `eirinifs.tar`. (see [eirinifs releases](https://github.com/cloudfoundry-incubator/eirinifs/releases))

    Additionally, if you want to override eirini images, please follow instructions in [Overriding Eirini Images](#overriding-eirini-images)

1. Use the following command to verify that every CF control plane pod is `running` and `ready`:

    ```bash
    watch kubectl get pods -n scf
    ```

## Notes

### Best practices for upgrading the kubernetes cluster

In order to upgrade the kubernetes version of your cluster without app downtime, we recommend that:
- You have at least three worker nodes. This helps preserve performance during the upgrade.
- You have at least 2 Gorouter instances by setting the `sizing.router.count` in your values.yaml file. This way your apps will allways be accessible.
- All apps are scaled to at least 2 instances. This way they can be upgraded one at a time ensuring no downtime.
- The node that is running the bits service is the last one to upgrade if possible. App migration depends on this service as it holds the docker images.

**Note**: If you follow these steps you will have no app downtime, although the kubernetes control plane as well as the 
cf push experience will go down for a certain amount of time.

### Overriding Eirini Images

Eirini has a few images which are deployed by the helm chart. By default these come from the eirini Docker Hub account and the versions of them are located in [the versions directory](helm/eirini/versions). These versions are sha256 sums of the images that will be installed by default. If you want to override any of these images please follow this table:

| Image               | Property                               | Default                      |
|---------------------|----------------------------------------|------------------------------|
| opi                 | `eirini.opi.image`                     | `eirini/opi`                 |
| opi-init            | `eirini.opi.init_image`                | `eirini/opi-init`            |
| secret-smuggler     | `eirini.opi.secret_smuggler_image`     | `eirini/secret-smuggler`     |
| bits-waiter         | `eirini.opi.bits_waiter`               | `eirini/bit-waiter`          |
| rootfs-patcher      | `eirini.opi.rootfs_patcher`            | `eirini/rootfs-patcher`      |
| loggregator-fluentd | `eirini.opi.loggregator_fluentd_image` | `eirini/loggregator-fluentd` |
| staging-images      | `eirini.opi.stager.downloader_image`   | `eirini/recipe-downloader`   |
|                     | `eirini.opi.stager.executor_image`     | `eirini/recipe-executor`     |
|                     | `eirini.opi.stager.uploader_image`     | `eirini/recipe-uploader`     |

By default, this is will install the `latest` tag of any image that was overriden. To change that, you'd have to set `eirini.opi.image_tag` as well. As of now, all the overriden images need to have same tag.
If a staging image needs to be updated, all the staging images must be updated.

### CF acceptance tests

As part of our development process we continuously test against the [Cloud Foundry Acceptance Tests](https://github.com/cloudfoundry/cf-acceptance-tests). Currently Eirini passes `110 tests`. The test suites that we currently have enabled are:

* apps
* detect
* docker
* internet_dependent
* routing
* services

The services suite is disabled in main ci due to flaking often. We additionally skip the [apps/buildpack-cache](https://github.com/cloudfoundry/cf-acceptance-tests/blob/5980e6f70aa4fe32e0207272326ae90a011a8c83/apps/buildpack_cache.go#L125) and [apps/reverse-log-proxy](https://github.com/cloudfoundry/cf-acceptance-tests/blob/master/apps/loggregator.go#L130) tests. The test suites that are currently skipped are:

* backend_compatibility
* credhub
* internetless
* isolation_segments
* route_services
* routing_isolation_segments
* security groups
* service discovery
* service instance sharing
* ssh
* tasks
* tcp routing
* v3
* volume servicess
* windows

#### Running CATs against Eirini

To run cats follow the instructions on the [cf-acceptance-tests repository](https://github.com/cloudfoundry/cf-acceptance-tests#test-execution). Use the following config and skip the aforementioned cats with the `-skip=uses the buildpack cache after first staging|reverse log proxy streams logs` flag for [./bin/test](https://github.com/cloudfoundry/cf-acceptance-tests/blob/5980e6f70aa4fe32e0207272326ae90a011a8c83/bin/test): 

```
    {
      "api": "api.yourdomain.com",
      "apps_domain": "yourdomain.com",
      "admin_user": "admin",
      "skip_ssl_validation": true,
      "use_http": true,
      "use_log_cache": false,
      "include_apps": true,
      "include_backend_compatibility": false,
      "include_capi_experimental": true,
      "include_capi_no_bridge": true,
      "include_container_networking": true,
      "include_credhub" : false,
      "include_detect": true,
      "include_docker": true,
      "include_deployments": false,
      "include_internet_dependent": true,
      "include_internetless": false,
      "include_isolation_segments": false,
      "include_private_docker_registry": false,
      "include_route_services": false,
      "include_routing": true,
      "include_routing_isolation_segments": false,
      "include_security_groups": false,
      "include_service_discovery": false,
      "include_services": true,
      "include_service_instance_sharing": false,
      "include_ssh": false,
      "include_sso": true,
      "include_tasks": false,
      "include_tcp_routing": false,
      "include_v3": false,
      "include_zipkin": true,
      "use_http": true,
      "include_volume_services": false,
      "stacks": [
        "cflinuxfs3"
      ]
    }
```

### Storage Class

It is highly recommended to use fast storage class for the blobstore. MySQL does
not work with NFS-based storage.

#### Using the HostPath Provisioner

As storage class, you can deploy a `hostpath` provisioner to your cluster. You can for example follow the documentation in this [repository](https://github.com/MaZderMind/hostpath-provisioner#dynamic-provisioning-of-kubernetes-hostpath-volumes). `hostpath` is not recommended for production use.

You can execute the following commands to have the `hostpath` provisioner installed in your Kubernetes cluster:

```bash
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml
```

#### Production Deployment

In a production settings ideally there should be existing storage classes that work with the deployment. In that case, you can either remove the `storage_class` properties from your `scf-config-values.yaml` file to use the default storage class, or alternatively set the properties to the storage class needed.

#### IBMCloud Kubernetes Service (IKS)

In IBM Kubernetes Service, it is recommended to use storage block storage class. See more how to enable it in [IBM Cloud documentation](https://console.bluemix.net/docs/containers/cs_storage_block.html#block_storage)

Additional details about deploying Eirini can be found in the `contrib` folder.

### Certificates

Please provide a serving certificate for bits service trusted by containerd/dockerd. In addition to usual globally trusted certificates, dockerd also supports self signed certificates. To know more about them please refer to [docker documentation](https://docs.docker.com/engine/security/certificates/).

However, containerd requires the signing authority for the registry certificate to be trusted OS wide. You could do this by getting a [Let's encrypt certificate](https://letsencrypt.org) or in IBMCloud Kubernetes Service, you could follow these instructions:

IKS provides ingress with a globally trusted certificate. The certificate is stored in a secret in the `default` namespace and has the same name as your cluster. You can use the following commands to export the certificates in the required environment variables:

```bash
CLUSTER_NAME=$(kubectl config current-context | cut -d / -f 1)
BITS_TLS_CRT="$(kubectl get secret "$CLUSTER_NAME" --namespace default -o jsonpath="{.data['tls\.crt']}" | base64 --decode -)"
BITS_TLS_KEY="$(kubectl get secret "$CLUSTER_NAME" --namespace default -o jsonpath="{.data['tls\.key']}" | base64 --decode -)"
```

It is recommended to deploy Eirini with ingress and use that certificate in IKS.
