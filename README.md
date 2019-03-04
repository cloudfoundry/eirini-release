# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini).

**NOTE**: This is an **_experimental_** release and is still considered _work in progress_.

## Prerequisites

* Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
* Install [helm](https://helm.sh/)

## Installation

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. For additional information you can take a look at [Storage Class](#storage-class)
1. Create a `values.yaml` based on [this](https://github.com/cloudfoundry-incubator/eirini-release/blob/master/values.yaml) template.
1. Make the Eirini helm repository available to helm:

    ```bash
    helm repo add eirini https://cloudfoundry-incubator.github.io/eirini-release
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

1. Install CF:

    ```bash
    helm install eirini/cf --namespace scf --name scf --set "secrets.UAA_CA_CERT=${CA_CERT}" --values <your-values.yaml>
    ```

1. Use the following command to verify that every CF control plane pod is `running` and `ready`:

    ```bash
    watch kubectl get pods -n scf
    ```

## Notes

### Storage Class

#### Using the HostPath Provisioner

As storage class, you can deploy a `hostpath` provisioner to your cluster. You can for example follow the documentation in this [repository](https://github.com/MaZderMind/hostpath-provisioner#dynamic-provisioning-of-kubernetes-hostpath-volumes). `hostpath` is not recommended for production use.

You can execute the following commands to have the `hostpath` provisioner installed in your Kube cluster:

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

## Resources

* [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm)
* [Eirini Continuous Integration Pipeline](https://ci.flintstone.cf.cloud.ibm.com/teams/eirini/pipelines/ci)