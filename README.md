# eirini-release

This is a BOSH release for [eirini](https://code.cloudfoundry.org/eirini).

- This is an **experimental** release and is still considered _work in progress_.
- In all examples, we refer to `bosh` as an alias to `bosh2` CLI.

## CI Pipeline

- [Eirini-CI](https://flintstone.ci.cf-app.com/teams/eirini/pipelines/eirini-ci)

## Deploy Eirini-Release

### Prereq's

Make sure to have the following tools deployed to your local machine:

- [Virtual Box](https://www.virtualbox.org/)
- [Docker](https://docs.docker.com/install/)
- [Bosh (v2) CLI](https://bosh.io/docs/cli-v2-install/)
- [CF CLI](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
- [minikube](https://github.com/kubernetes/minikube#installation)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- Ruby ( v > 2.4:`capi-release` still uses pre-packaging)
- Golang

### Deploying

The deploy script will fetch all necessary resources into a folder that is determined by the environment variable `$EIRINI_LITE`. When not set, the default will be `~/workspace/eirini-lite`.

1. Get `eirini-release`

	 Clone `eirini-release` to your local machine into `$EIRINI_LITE`.
	 
1. Execute the deploy script:

   ```
   $ source $EIRINI_LITE/eirini-release/scripts/lite/come-on-eirini.sh
   ```

   This script will setup bosh-lite, minikube, plus eirini on your local machine. Moreover it will setup an `eirini` org and `dev` space on CF, such that you are ready to push some apps right after the script finished its work (which takes a while). 

   If you want to do things manually or have a running Bosh-Lite and CF, you can take a look at our script `scripts/lite/setup-eirini-environment.sh`. It should explain the steps necessary thoroughly. 

## Contributing

1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository
