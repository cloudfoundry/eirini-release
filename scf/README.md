# SCF + Eirini

You are basically two `helm install's` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed. 

## Prereqs:

- Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes). 
- Install [helm](https://helm.sh/)

### Minikube [in progress and not fully tested yet]

If you want to deploy to `minikube` you will need to do some additional steps before you start:

1. Start minikube with RBAC enabled and enough resources: `minikube start --extra-config=apiserver.Authorization.Mode=RBAC --cpus 4 --disk-size 100g --memory 8192`
1. Install Tiller with a serviceaccount:

   ```bash
   $ helm init
   $ kubectl create serviceaccount --namespace kube-system tiller
   $ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
   $ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
   ```
1. Apply the `persistent` storage class:

   ```yaml 
   ---
   kind: StorageClass
   apiVersion: storage.k8s.io/v1beta1
   metadata:
     name: persistent
     annotations:
       storageclass.kubernetes.io/is-default-class: "true"
   provisioner: kubernetes.io/host-path
   parameters:
     path: /tmp	 
	 ```

	 Save the above content to a file and run `$ kubectl create -f <your-file-name>`

Note: The experience on minikube is really slow!

## Deploy

1. Choose a [non NFS based `StorageClass`](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class) because MySQL does not work well with it. 
1. Configure your deployment as described in the [SCF configurations docs](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#configuring-the-deployment) 
   
   Add Eirini-specific values to the `scf-config-values.yml` file:

   ```yaml
   env:
     EIRINI_KUBE_ENDPOINT: <kube-endpoint>
     EIRINI_REGISTRY_ADDRESS: <node-ip>:5800
     EIRINI_KUBE_CONFIG: <kube-config>
   ```

   - `EIRINI_KUBE_ENDPOINT`: This is the API endpoint of your Kube cluster. 
   - `EIRINI_REGISTRY_ADDRESS`: The `eirini-registry` is exposed via NodePort `5800`. So the node-ip has to match any `worker` node in your kube cluster. 
   - `EIRINI_KUBE_CONFIG`: 

   One way to get your kube-config as compact escaped json is:

   ```bash 
   $ kubectl config view --flatten -o json | ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load(ARGF))' | sed 's/\"/\\\"/g'
   ```

1. Create the well-known namespace `eirini`:

   ```bash
   $ kubectl create namespace eirini
   ```

   All apps will be deployed to this namespace.

1. Deploy SCF by following the steps in [this](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm) section. The remainder of that document is optional.

1. Enjoy Eirini ;)
