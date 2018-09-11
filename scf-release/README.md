# Install SCF + Eirini

You are basically two `helm install's` away from deploying `SCF` with `Eirini`. But before you can execute helm you have to do some basic setup. The instructions below will guide you through the necessary steps and redirect you to the official [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF) whenever needed. 

Before you start, make sure your Kubernetes cluster meets all SCF related requirments. You can read about them [here](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#requirements-for-kubernetes). 

1. Choose a non NFS based `StorageClass` because MySQL does not work well with it. For more information read [here](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#choosing-a-storage-class)
1. Configure your deployment as described [here](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#configuring-the-deployment) and add Eirini-specific values to the `scf-config-values.yml` file:

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

1. Create the `eirini` namespace:

   ```bash
   $ kubectl create namespace eirini
   ```

   All apps will be deployed to this namespace.

1. Deploy SCF by following the steps in [this](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm) section.  
1. Deploying the Stratos UI is up to you :) 
