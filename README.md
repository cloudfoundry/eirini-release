# cube-release
This is a BOSH release for [cube](https://github.com/julz/cube).

## Description
_Note_: This is an **Experimental** release and is still considered _work in progress_.<br />
_Note_: In all examples, we refer to `bosh` as an alias to `bosh2` CLI.<br />

## Prereq
1. Install **Minikube** on your system. Follow the [instructions](https://github.com/kubernetes/minikube#installation) to get required tools.
1. Start your **Minikube**
```
minikube start
```
It might take some time until you see `Kubectl is now configured to use the cluster`, which indicates we are ready to continue.
1. Deploy and run a BOSH director. For example, refer to [Stark and Wayne's tutorial](http://www.starkandwayne.com/blog/bosh-lite-on-virtualbox-with-bosh2/) on how set-up such a BOSH Lite v2 environment.
1. Run Cloud Foundry on your BOSH Lite environment using the [cf-deployment](https://github.com/cloudfoundry/cf-deployment). Again, you can refer to another [Stark and Wayne's tutorial](https://www.starkandwayne.com/blog/running-cloud-foundry-locally-on-bosh-lite-with-bosh2/).

## Build
Create release from source and upload to BOSH director.
```sh
bosh sync-blobs
git submodule update --init --recursive
bosh create-release
bosh -e <your-env-alias> upload-release
```

## Deploying
- Target your API and push an [app](https://github.com/cloudfoundry/cf-acceptance-tests/tree/master/assets/dora).
  ```
   cf login -a https://api.bosh-lite.com \
       -u "admin" \
       -p "$(bosh2 int <path-to-cf-deployment>/deployment-vars.yml --path /cf_admin_password)" \
       --skip-ssl-validation
  if ! cf org test-org > /dev/null 2>&1; then cf create-org test-org; fi
  if ! cf space test-space > /dev/null 2>&1; then cf create-space test-space -o test-org; fi
  cf target -o test-org -s test-space
  cf push test-app-name
  ```
- Use `kubectl config view` to get your Minikube configuration. You have to manually read the content of referenced files in there to place the content into the YAML configuration rather than reference it by the path, for example:
 ```yaml
 [...]
 users:
 - name: minikube
   user:
     as-user-extra: {}
     client-certificate: /Users/user/.minikube/client.crt  <- file reference to be replaced by plain value
     client-key: /Users/user/.minikube/client.key  <- file reference to be replaced by plain value
 ```
 After replacing the content, it should look like this:
 ```yaml
 [...]
 users:
 - name: minikube
   user:
     as-user-extra: {}
     client-certificate: |
     -----BEGIN CERTIFICATE-----
     ASDFATTFASDFASDFASDFSADFASDFGTT
     [...]
 ```
 There could be a script to do this in the future.
- Copy your Minikube configuration file and paste the whole YAML structure into provided [BOSH operations file](operations/cube-operations.yml) inside `properties.cube_sync.config`:

 ```yaml
 - type: replace
     path: /instance_groups?/-
     value:
       name: cube
       [..]
       jobs:
       - name: cube_sync
         properties:
           cube_sync:
             config:
               your Kubernetes configuration must be placed here (watch for the correct indentation)
 ```
- Modify and deploy your `cf-deployment` using the provided [BOSH operations file](operations/cube-operations.yml):
```
bosh -e <your-env-alias> -d cf deploy <path-to-cf-deployment>/cf-deployment.yml \
    -o <path-to-cf-deployment>/operations/bosh-lite.yml \
    -o operations/cube-operations.yml \
    --vars-store <path-to-cf-deployment>/deployment-vars.yml \
    -v system_domain=bosh-lite.com
```
The above modification, will add a new VM(`cube`) to the deployment, and will use some existing keys to populate the new `instance_group` properties.

## Properties
| Path | Description |
| ------------- | --------------|
| `cube_sync.ccAPI` | The API endpoint of the Cloud Controller |
| `cube_sync.ccUser` | The internal username for the Cloud Controller (default: `internal_user` |
| `cube_sync.ccPassword` | The internal password for the Cloud Controller |
| `cube_sync.backend` | The backend to use (default: `k8s`) |
| `cube_sync.config` | The full Kubernetes configuration file content.<br />_Note_: Avoid using certificates file references, instead you should use the file content. |


## TODO
- [ ] Create a script to get a Kubernetes configuration file with certificates and keys replaced by the values from the files that are referenced in there.


## Contributing
1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository
