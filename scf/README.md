# SCF + Eirini

You are basically two `helm install's` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed. 

## Prereqs:

- Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes).
- Install [helm](https://helm.sh/).
- Currently, Eirini only works with a single node Kubernetes cluster.

### Minikube [not recommended!]

Please note, that we could not fully test the SCF installation on `minikube` yet and that the experience on `minikube` is really slow! 

If you want to deploy to `minikube` you will need to do some additional steps before you start:

1. Start minikube with RBAC enabled and enough resources: `minikube start --extra-config=apiserver.Authorization.Mode=RBAC --cpus 4 --disk-size 100g --memory 8192`
1. Install Tiller with a serviceaccount:

   ```bash
   $ helm init
   $ kubectl create serviceaccount --namespace kube-system tiller
   $ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
   $ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
   ```

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
     use_ingress: false


   secrets:
     NATS_PASSWORD: changeme
	```

1. Deploy SCF by following the steps in [this](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm) section. The remainder of that document is optional.

1. Enjoy Eirini ;)

### Cloud Specifics


#### IBMCloud Container Service (Kubernetes)

- As storage class, you should deploy a `hostpath` provisioner to your cluster. You can for example follow the documentation in this [repository](https://github.com/MaZderMind/hostpath-provisioner#dynamic-provisioning-of-kubernetes-hostpath-volumes). The reason for this is that the `database` jobs in SCF are not working with the existing storage classes.
You can execute the following commands:
```
$ kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/rbac.yaml
$ kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/deployment.yaml
$ kubectl create -f https://raw.githubusercontent.com/MaZderMind/hostpath-provisioner/master/manifests/storageclass.yaml
```
