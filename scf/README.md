# SCF + Eirini

You are basically two `helm install's` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed.

## Prereqs:

- Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
- Install [helm](https://helm.sh/)
- We recommend to deploy this release on a single-worker Kube cluster.

## Deploy

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. For additional information you can take a look at [Cloud Specifics](#cloud-specifics)
1. Configure your deployment as described in the [SCF configurations docs](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#configuring-the-deployment)

   Add eirini-specific values to the `scf-config-values.yml` file:

    ```yaml
    env:
      # To disable diego and use eirini/opi staging, uncomment the following parameter:
      # ENABLE_OPI_STAGING: true

    opi:
      # The ingress sub-domain or IP
      ingress_endpoint: <ingress-endpoint>

      # The namespace eirini/opi schedules the apps to.
      namespace: <kubernetes-namespace>

      # if this property is set to true it will expose the
      # registry via ingress, default is to NodePort.
      use_registry_ingress: false

      # set to false if you don't want Eirini to create ingress rules for apps
      use_app_ingress: true

    secrets:
      NATS_PASSWORD: changeme
    ```

1. Deploy SCF by following the steps in [this](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm) section. The remainder of that document is optional.

1. Enjoy Eirini ;)

### Cloud Specifics

#### IBMCloud Container Service (Kubernetes)

As storage class, you should deploy a `hostpath` provisioner to your cluster. You can for example follow the documentation in this [repository](https://github.com/MaZderMind/hostpath-provisioner#dynamic-provisioning-of-kubernetes-hostpath-volumes). The reason for this is that the `database` jobs in SCF are not working with the existing storage classes.

You can execute the following commands:

```console
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml
```

#### Community Tested

##### [Gardener](https://gardener.cloud)

- This has been tested with a single node Gardener-provisioned Kubernetes cluster deployed to Google Cloud.
- In addition to the configuration provided in the [Deploy](#deploy) section, amend `scf-config-values.yml` with the following values:

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
