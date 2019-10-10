# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini).

**NOTE**: This is an **_experimental_** release and is still considered _work in progress_.

## Table of contents

* [Prerequisites](#prerequisites)
  * [Minimum cluster requirements](#minimum-cluster-requirements)
* [Installation](#installation)
* [Notes](#notes)
  * [Overriding Eirini Images](#overriding-eirini-images)
  * [Diego staging](#diego-staging)
  * [CF acceptance tests](#cf-acceptance-tests)
    * [Running CATs against Eirini](#running-cats-against-eirini)
  * [Storage Class](#storage-class)
    * [Using the HostPath Provisioner](#using-the-hostpath-provisioner)
    * [Production Deployment](#production-deployment)
    * [IBMCloud Kubernetes Service (IKS)](#ibmcloud-kubernetes-service-iks)
  * [Certificates](#certificates)
  * [Service Account](#service-account)
  * [Network policies](#network-policies)
    * [Securing SCF endpoints](#securing-scf-endpoints)
    * [Securing Kubernetes API Endpoint](#securing-kubernetes-api-endpoint)
* [Troubleshooting](#troubleshooting)
  * [Disk full on blobstore](#disk-full-on-blobstore)
* [Resources](#resources)

## Prerequisites

* Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
* Install [Metrics server](https://github.com/kubernetes-incubator/metrics-server) in the system namespace
* Install [helm](https://helm.sh/)
* To be able to use the [bits service](https://github.com/cloudfoundry-incubator/bits-service) private registry in your Kubernetes cluster,
you need to have a signed TLS certificate, with a CA that the docker or containerd daemon on the nodes trust, and a CN that is pointing to the bits service.

**Note**: Eirini is currently being tested with HELM > 2.14.1, Kubernetes 1.13, and containerd as the container runtime.

### Minimum cluster requirements

We have validated that the deployment can start with a single-node 4 core 16GB cluster, although the initial startup will be very slow with this setup.
We recommend at least 8 cores and 16GB of RAM for the SCF control plane and at least two additional nodes that you can scale relative to the average consumption
of resource of the applications that you will be deploying. To make staging of applications faster with Diego, operators should scale the Diego cells to the number of additional nodes.

## Installation

### GKE-specific instructions

Follow instructions [here](./docs/gke.md).

### General instructions

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. For additional information you can take a look at [Storage Class](#storage-class)
1. Create a `values.yaml` based on [this](./values.yaml) template.
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

### Diego staging

By default, Eirini now stages applications using Kubernetes pods. This currently breaks some [CATS](https://github.com/cloudfoundry/cf-acceptance-tests). For list of CATS that
are breaking in our pipeline you can check our [CI config](https://github.com/cloudfoundry-incubator/eirini-ci/blob/master/pipelines/modules/opi-skipped-cats.yml).
You can enable staging using Diego by add `ENABLE_OPI_STAGING: false` in `env` section of your values.yaml. This will use more resources.

### CF acceptance tests

As part of our development process we continuously test against the [Cloud Foundry Acceptance Tests](https://github.com/cloudfoundry/cf-acceptance-tests). Currently Eirini (with OPI staging enabled) passes `110 tests`. The test suites that we currently have enabled are:
* apps
* detect
* internet_dependent
* routing
* services

We additionally skip the [apps/buildpack-cache](https://github.com/cloudfoundry/cf-acceptance-tests/blob/5980e6f70aa4fe32e0207272326ae90a011a8c83/apps/buildpack_cache.go#L125) and [apps/reverse-log-proxy](https://github.com/cloudfoundry/cf-acceptance-tests/blob/master/apps/loggregator.go#L130) tests. The test suites that are currently skipped are:
* ssh
* v3
* service instance sharing
* service discovery
* tcp routing
* internetless
* security groups
* backend_compatibility
* route_services
* internetless
* isolation_segments
* tasks
* windows
* routing_isolation_segments
* docker
* credhub
* volume servicess

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
      "include_docker": false,
      "include_deployments": true,
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
BITS_TLS_CRT="$(kubectl get secret "$(kubectl config current-context)" --namespace default -o jsonpath="{.data['tls\.crt']}" | base64 --decode -)"
BITS_TLS_KEY="$(kubectl get secret "$(kubectl config current-context)" --namespace default -o jsonpath="{.data['tls\.key']}" | base64 --decode -)"
```

It is recommended to deploy Eirini with ingress and use that certificate in IKS.

### Service Account

When an app is pushed with Eirini, the pods are assigned the default Service Account in `opi.namespace`. By default, when the cluster is deployed with `RBAC` authentication method, that Service Account should not have any read/write permissions to the Kubernetes API. Since `RBAC` is preffered to `ABAC`, we recommend using the former.

### Network policies

Apps pushed by Eirini currently cannot be accessed directly from another app container. This is accomplished by creating a [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resource in the namespace in which Eirini deploys apps.

In order to use network policies in your cluster, you must use a compatible container network plug-in, otherwise creating a `NetworkPolicy` resource will have no effect.

Both [IKS](https://cloud.ibm.com/docs/containers?topic=containers-network_policies) (is automatically setup) and [GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy#enabling_network_policy_enforcement) (has to be enabled) support a network plug-in called [Calico](https://www.projectcalico.org/), which supports defining network policies.

For other implementations of the Kubernetes networking model, take a look [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model). Keep in mind that not all implementations support defining network polcies (e.g. Flannel). For a more detailed comparison between different plugins, take a look [here](https://docs.google.com/spreadsheets/d/1qCOlor16Wp5mHd6MQxB5gUEQILnijyDLIExEpqmee2k/edit#gid=0) (not maintained by us).

#### Securing SCF endpoints

It is not possible to do it with native Kubernetes network policies. In order to achieve this, the CNI plugin can be used directly. If you're using [Calico](https://www.projectcalico.org/) on IBMCloud, you can run the following command:

```bash
calicoctl apply --config $CALICOCNF -f - <<EOF
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: deny-scf-access
  namespace: eirini
spec:
  types:
  - Egress
  egress:
  - action: Deny
    source:
      selector: source_type == 'APP'
    destination:
      namespaceSelector: name == 'scf'
  - action: Allow
EOF
```

You can use [this](https://www.ibm.com/cloud/blog/configure-calicoctl-for-ibm-cloud-kubernetes-service) guide to export `$CALICOCNF` on IBM Cloud.

Note that GKE does not currently support creating custom Calico network policies.

#### Securing Kubernetes API Endpoint

The Kubernetes API is available in all pods by default at `https://kubernetes.default`. Eirini does not mount
service account credentials to the pod and uses default service account in the namespace. This prevents Eirini pods from using Kubernetes API.
To completely disallow access to this from application instances, you'd need to apply this network policy:

```yaml
apiVersion: extensions/v1beta1
kind: NetworkPolicy
metadata:
  name: eirini-egress-policy
  namespace: eirini
spec:
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - <API IP Address>/32
  podSelector: {}
  policyTypes:
  - Egress
```

You can get IP address of the master by running `kubectl get endpoints` command. If there are multiple Kubernetes API nodes, IP address
of each of them would need to be specified in the `except` array.

## Troubleshooting

### Disk full on blobstore

If all the CF apps are running, it is safe to delete all files in `/var/vcap/store/shared/cc-droplets/sh/a2/` directory on the `blobstore-0` pod.
To do so, you can run this command:

```bash
kubectl exec -n <scf-namespace> blobstore-0 -c blobstore -- \
  /bin/sh -c 'rm -rf /var/vcap/store/shared/cc-droplets/sh/a2/sha256:*'
```

## Resources

* [Security](./docs/security-overview.md)
* [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm)
* [Eirini Continuous Integration Pipeline](https://ci.eirini.cf-app.com/teams/main/pipelines/eirini-release)
