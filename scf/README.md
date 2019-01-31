# Containerized Cloud Foundry (SCF) + Eirini

You are basically two `helm installs` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed.

## Prerequisites:

- Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
- Install [helm](https://helm.sh/)

## Deploy

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. For additional information you can take a look at [Cloud Specifics](#cloud-specifics)
1. Clone or download and unzip the latest  [Eirini Release](https://github.com/cloudfoundry-incubator/eirini-release/releases)
1. Create a `scf-config-values.yaml` file under `eirini-release/scf/helm`, using the following template:
    ```yaml
    env:
      # should be a `domain` name that resolves to any of your non-master cluster nodes
      # alternatively, you can use `nip.io` and public IP for any of your non-master nodes
      # in the form of `x.x.x.x.nip.io`
      DOMAIN: <cf-domain-address>
      # `uaa.doamin` or `uaa.x.x.x.x.nip.io` as mentioned above
      UAA_HOST: <cf-uaa-address>
      # default UAA_PORT is 2793
      UAA_PORT: <cf-uaa-port>
      # to disable diego and use eirini/opi staging, set the following parameter to `true`
      # if set to `false`, diego cells are used to stage the droplet and create the application OCI image
      ENABLE_OPI_STAGING: false

    kube:
      auth: rbac
      # list all the kube node ips
      external_ips:
      - <kube-node-ip>
      storage_class:
        persistent: <storage-class>
        shared: <storage-class>

    opi:
      # if this property is set to true it will expose the
      # registry via ingress, default is to NodePort.
      use_registry_ingress: false

      # the ingress sub-domain or IP
      # you can ignore this porperty if use_registry_ingress is set to `false`
      ingress_endpoint: <ingress-endpoint>

      # the namespace eirini/opi schedules the apps to.
      namespace: <kubernetes-namespace>

      # if you clone the eirini-release repo you need to explicitly specify the image tag.
      # when downloading the release tarball, `image_tag` is already set to the release version
      # (see https://hub.docker.com/r/eirini/opi/tags), in which case you can drop the following property.
      image_tag: <some-tag>

    secrets:
      NATS_PASSWORD: changeme
      CLUSTER_ADMIN_PASSWORD: changeme
      UAA_ADMIN_CLIENT_SECRET: changeme

      # when using Bits-Service as image registry:
      BITS_SERVICE_SECRET: changeme
      BITS_SERVICE_SIGNING_USER_PASSWORD: changeme
      BLOBSTORE_PASSWORD: changeme
    ```
   More information on the SCF deployment configurations can be found in the [SCF configurations docs](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#configuring-the-deployment)

1. To deploy from a cloned eirini-release `cd` into `eirini-release/scf/helm` and you will find the helm charts for `cf` and `uaa`. If downloading the release, `cf` and `uaa` helm charts are available at the root of the unzipped and extracted release.
1. Use the following commands as explained in the [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm). In the commands `uaa` and `cf` refer to the helm chart directories from `eirini-release/scf/helm`:

    ```bash
    $ helm install uaa --namespace uaa --values scf-config-values.yaml --name uaa
    $ SECRET=$(kubectl get pods --namespace uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
    $ CA_CERT="$(kubectl get secret $SECRET --namespace uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
    $ helm install cf --namespace scf --name scf --values scf-config-values.yaml --set "secrets.UAA_CA_CERT=${CA_CERT}"
    ```

1. Enjoy Eirini ;)

### Storage Class

#### Using the HostPath Provisioner

As storage class, you can deploy a `hostpath` provisioner to your cluster. You can for example follow the documentation in this [repository](https://github.com/MaZderMind/hostpath-provisioner#dynamic-provisioning-of-kubernetes-hostpath-volumes). `hostpath` is not recommended for production use.

You can execute the following commands to have the `hostpath` provisioner installed in your Kube cluster:

```console
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml
```
#### Production Deployment

In a production settings ideally there should be existing storage classes that work with the deployment. In that case, you can either remove the `storage_class` properties from your `scf-config-values.yaml` file to use the default storage class, or alternatively set the properties to the storage class needed.

#### IBMCloud Kubernetes Service (IKS)

In IBM Kubernetes Service, existing storage classes sometimes fail when used with the `database` jobs in SCF. The issue exhibits itself when starting the `switchboard` process for the `mysql` job in `uaa` or `scf` deployments in the following form:

```
failed to delete arp entry: OUTPUT=SIOCDARP(priv): Operation not permitted
exit status 255
ERROR=exit status 1
```

When facing the problem, you can either try deleting the persistent volume claims and redeploying SCF + Eirini or you can fall back to creating a `hostpath` storage class provisioner and use `hostpath` instead.

#### Community Tested

##### [Gardener](https://gardener.cloud)

- This has been tested with a single node Gardener-provisioned Kubernetes cluster deployed to Google Cloud.
- In addition to the configuration provided in the [Deploy](#deploy) section, amend `scf-config-values.yaml` with the following values:

    ```yaml
    env:

      # ...

      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537459332000100
      # needs to match the IP range of your K8s pods (see Gardener cluster YAML at
      # spec.cloud.gcp.networks.pods)
      BLOBSTORE_ACCESS_RULES: allow 100.96.0.0/11;

      # ...

      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537511390000100?thread_ts=1537509203.000100&cid=C8RU3BZ26
      GARDEN_ROOTFS_DRIVER: overlay-xfs
      GARDEN_APPARMOR_PROFILE: ""

      # ...

    opi:
      # see Gardener dashboard for your cluster -> Infrastructure -> Ingress
      # Domain; replace '*' with 'default'
      ingress_endpoint: <ingress-endpoint>

      # ...

    services:
      loadbalanced: true

    kube:
      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537517553000100?thread_ts=1537509203.000100&cid=C8RU3BZ26
      # The internal (!) IP address assigned to the kube node pointed to by the
      # domain.
      external_ips:
      - <internal-ip>

      storage_class:
        persistent: "default"
        shared: "default"

      # ...
    ```
