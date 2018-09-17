# SCF + Eirini

You are basically two `helm install's` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed. 

## Deployment Options

- [The fissiled way](#deploy---the-fissiled-way)
- [The native way](#the-native-way)

## Prereqs:

- Make sure your Kubernetes cluster meets all [SCF related Kubernetes Requirements](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes). 
- Install [helm](https://helm.sh/)

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

## Deploy - The fissiled way

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

1. Deploy SCF by following the steps in [this](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm) section. The remainder of that document is optional.

   _Info: All apps will be deployed to this namespace._

1. As the `eirini registry` has no secure endpoint it needs to be added as `insecure registry` to the docker daemon. More information about this can be found in the [Docker Doc](https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry). In Kubernetes the `daemon.json` needs to be applied on every worker node. The IP is one of the IPs you specified as external: `<externalIP>:5800`. This usually requires a node reboot. 

  _Tip: If you don't have direct access to the nodes you could use a Pod with priviliged access to add the `daemon.json`._

1. Enjoy Eirini ;)

## The native way

This approach deploys an non-fissiled `eirini` container image with `scf`. It has several advantages from `opi/eirini` perspective:

- No need to provide the `kube-config` to the deployment. `OPI` will use `in-cluster config` (this is not possible with a fissiled docker image).
- You can access logs directly by using `kubectl logs <eirini-pod> [opi|registry]`

### Deploy 

1. To deploy follow the steps in `The fissiled way` but provide a simplified config. Copy the config from the [SCF configurations docs](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#configuring-the-deployment) and add the following values:

   ```yaml
   env:
     EIRINI_KUBE_ENDPOINT: <kube-endpoint>

   secrets:
     NATS_PASSWORD: changeme
	```

  _Note that the kube-config isn't required anymore_

1. Replace every command that includes the `helm` directory with the `hnative` directory (eg `$ helm install helm/cf` -> `$ helm install hnative/cf`)

_Note: It can take a while `eirini` comes up._
