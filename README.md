# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini).

**NOTE**: This is an **_experimental_** release and is still considered _work in progress_.

## Prerequisites

* Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
* Install [Heapster](https://github.com/kubernetes-retired/heapster/) in the system namespace
* Install [helm](https://helm.sh/)
* To be able to use the [bits service](https://github.com/cloudfoundry-incubator/bits-service) private registry in your Kubernetes cluster, you need to have a signed TLS certificate, with a CA that the docker or containerd daemon on the nodes trust, and a CN that is pointing to the bits service.

**Note**: Eirini is currently being tested with HELM > 2.13.1, Kubernetes 1.11, and containerd as the container runtime.

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

1. Export the Registry certificate in the `BITS_TLS_KEY` and `BITS_TLS_CRT` environment variables. (see [Certificates](#Certificates))

1. Install CF:

    ```bash
    helm install eirini/cf --namespace scf --name scf --values <your-values.yaml> --set "secrets.UAA_CA_CERT=${CA_CERT}" --set "eirini.secrets.BITS_TLS_KEY=${BITS_TLS_KEY}" --set "eirini.secrets.BITS_TLS_CRT=${BITS_TLS_CRT}" 
    ```

    **NOTICE**

    The above command will take the default value for `rootfs_tag`. In case you want to specify a rootfs_version at deploy time use

    ```bash   
    --set "eirini.opi.rootfs_tag=x.x.x" 
    ```

This will download the mentioned version of `eirinifs.tar`. (see [eirinifs releases](https://github.com/cloudfoundry-incubator/eirinifs/releases))
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

## Resources

* [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm)
* [Eirini Continuous Integration Pipeline](https://ci.flintstone.cf.cloud.ibm.com/teams/eirini/pipelines/ci)
