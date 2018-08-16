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

The deploy script will fetch all necessary resources into the folder you cloned the `eirini-release`.

1. Get `eirini-release` by cloning it to your local machine.
1. Execute the deploy script:

   ```
   $ source eirini-release/scripts/lite/come-on-eirini.sh
   ```

   This script will setup bosh-lite, minikube, plus eirini on your local machine. Moreover it will setup an `eirini` org and `dev` space on CF, such that you are ready to push some apps right after the script finished its work (which takes a while).

   If you want to do things manually or have a running Bosh-Lite and CF, you can take a look at our script `scripts/lite/setup-eirini-environment.sh`. It should explain the steps necessary thoroughly.

#### Enable logging

To enable logging with `log-cache` you need to deploy oratos on your kubernetes cluster. To do this follow the instructions on the `eirini` branch on [this repo](https://github.com/gdankov/oratos-deployment/tree/eirini). To get the logs of your app use the [log-cache cli](https://github.com/cloudfoundry/log-cache-cli#stand-alone-cli) with the following format
```bash
$ log-cache tail <app_guid>
```
You can also use `cf` directly by installing the [log-cache plugin](https://github.com/cloudfoundry/log-cache-cli#installing-plugin) and using
```bash
$ cf tail <app_name>
```
You can get the _<app_guid>_ by running `cf app <app_name> --guid`

**Note**: before calling any of `log-cache` or `cf tail` you *must* export the `LOG_CACHE_ADDR` environment variable as specified [here](https://github.com/gdankov/oratos-deployment/tree/eirini#accessing-logs-via-logcache).

_Example calls_:
``` bash
$ log-cache tail 05f501f4-569f-429d-a3f5-bedc15b923b5
$ cf tail dora
```

### Run Smoke Tests

1. Clone [CF-Smoke-Tests](https://github.com/cloudfoundry/cf-smoke-tests)
1. Setup the smoke tests by following the [test-setup](https://github.com/cloudfoundry/cf-smoke-tests#test-setup) provided in the cf-smoke-tests readme.
1. Navigate to the `smoke-tests` directory and run the smoke tests as follows:

  ```bash
  $ bin/test -r -skip="/logging/loggregator_test.go" --regexScansFilePath=true
  ```
  This will disable the `logging` tests, as `logging` is currently not supported by `eirini`.

## Contributing

1. Fork this project into your GitHub organisation or username
1. Make sure you are up-to-date with the upstream master and then create your feature branch (`git checkout -b amazing-new-feature`)
1. Add and commit the changes (`git commit -am 'Add some amazing new feature'`)
1. Push to the branch (`git push origin amazing-new-feature`)
1. Create a PR against this repository
