# eirini-release
This is a BOSH release for [eirini](https://code.cloudfoundry.org/eirini).

## Description
_Note_: This is an **Experimental** release and is still considered _work in progress_.<br />
_Note_: In all examples, we refer to `bosh` as an alias to `bosh2` CLI.<br />

## Prereq
1. Install **Minikube** on your system. Follow the [instructions](https://github.com/kubernetes/minikube#installation) to get the required tools.
1. Start your **Minikube** in the same network as Bosh-Lite (in future) and add cube-registry as insecure-registry:
    ```sh
    minikube start --host-only-cidr 192.168.50.1/24 --insecure-registry="10.244.0.142:8080"
    ```

    *NOTE*: if something changes on your minikube config (eg new IP or cube address changes) you will need to redeploy (delete and recreate) minikube. 

    It might take some time until you see `Kubectl is now configured to use the cluster`, which indicates we are ready to continue.
1. Deploy and run a BOSH director. For example, refer to [Stark and Wayne's tutorial](http://www.starkandwayne.com/blog/bosh-lite-on-virtualbox-with-bosh2/) on how set-up such a BOSH Lite v2 environment.
1. Run Cloud Foundry on your BOSH Lite environment using the [cf-deployment](https://github.com/cloudfoundry/cf-deployment). Again, you can refer to another [Stark and Wayne's tutorial](https://www.starkandwayne.com/blog/running-cloud-foundry-locally-on-bosh-lite-with-bosh2/).
1. You will need a running docker on your machine to create the `eirinifs`

## Deploying

1. Create the `eirinifs.tar` and add it to `blobs`
   
   ```
   $ git submodule update --init --recursive

   $ scripts/buildfs.sh
   ```

   The `scripts/buildfs.sh` script will create the `eirinifs.tar` and add it to `blobs`. 

   *NOTE*: You may need to go get required packages if you get issues with the `buildfs.sh` script. 

1. Target your API and push an [app](https://github.com/cloudfoundry/cf-acceptance-tests/tree/master/assets/dora).
    ```
    cf login -a https://api.bosh-lite.com \
         -u "admin" \
         -p "$(bosh2 int <path-to-cf-deployment>/deployment-vars.yml --path /cf_admin_password)" \
         --skip-ssl-validation

    if ! cf org test-org > /dev/null 2>&1; then cf create-org test-org; fi
    if ! cf space test-space > /dev/null 2>&1; then cf create-space test-space -o test-org; fi
    cf target -o test-org -s test-space
    ```
    Change into the source directory of the app you want to push.
    ```
    cf push test-app-name
    ```
1. Modify and deploy your `cf-deployment` using the provided [BOSH operations file](./operations/cube-bosh-operations.yml):
    - **Build** your release and **deploy**
      ```
      bosh sync-blobs
      bosh create-release
      bosh -e <your-env-alias> upload-release

      bosh -e <your-env-alias> -d cf deploy <path-to-cf-deployment>/cf-deployment.yml \
           -o <path-to-cf-deployment>/operations/experimental/enable-bpm.yml \
	   -o <path-to-cf-deployment>/operations/experimental/use-bosh-dns.yml \
           -o <path-to-cf-deployment>/operations/bosh-lite.yml \
           -o <path-to-cube-release>/operations/cube-bosh-operations.yml \
           --vars-store <path-to-cf-deployment>/deployment-vars.yml \
           --var=k8s_flatten_cluster_config="$(kubectl config view --flatten=true)" \
           -v system_domain=bosh-lite.com \
	   -v cube_address="http://10.244.0.142:8085" \
           -v cc_api=https://api.bosh-lite.com \
	   -v cube_ip="10.244.0.142"
      ```

      When deploying cube to CF on bosh-lite it should get the IP `10.244.0.142`. If you get another IP you should redeploy with the correct address. I know this is not the optimal solution and will be changed in future to be dynamic. ;) 

    - Or **Build and deploy** with one command as a dev release
      ```
      bosh -e <your-env-alias> -d cf deploy <path-to-cf-deployment>/cf-deployment.yml \
           -o <path-to-cf-deployment>/operations/experimental/enable-bpm.yml \
	   -o <path-to-cf-deployment>/operations/experimental/use-bosh-dns.yml \
           -o <path-to-cf-deployment>/operations/bosh-lite.yml \
           -o <path-to-cube-release>/operations/cube-bosh-operations.yml \
           --vars-store <path-to-cf-deployment>/deployment-vars.yml \
           --var=k8s_flatten_cluster_config="$(kubectl config view --flatten=true)" \
           -v system_domain=bosh-lite.com \
           -v cc_api=https://api.bosh-lite.com \
           -o <path-to-cube-release>/operations/dev-version.yml \
	   -v cube_address="http://10.244.0.142:8085" \
	   -v cube_ip="10.244.0.142" \
           -v cube_local_path=<path-to-eirini-release>
      ```
    The above modification, will add a new VM(`eirini`) to the deployment, and will use your current **Minikube** config file to populate the `properties.cube_sync.config` of your manifest.

1. In order to see if a droplet migration to the cluster was successful, you can run  `kubectl get pods` to double check.

## Properties
| Path | Description |
| ------------- | --------------|
| `eirini_sync.ccAPI` | The API endpoint of the Cloud Controller |
| `eirini_sync.ccUser` | The internal username for the Cloud Controller (default: `internal_user`) |
| `eirini_sync.ccPassword` | The internal password for the Cloud Controller |
| `eirini_sync.backend` | The backend to use (default: `k8s`) |
| `eirini_sync.config` | The full Kubernetes configuration file content. <br /> _Note_: Avoid using certificates file references, instead you should use the file content by using the `flatten` option to retrieve your configuration YAML. |


## Contributing
1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository

