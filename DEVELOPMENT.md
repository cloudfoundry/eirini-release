# Development

This document assumes that you have access to the eirini development environment including IBMCloud, Private Repositories, etc.

1. Checkout Sources

  - [eirini-ci](https://github.com/cloudfoundry-incubator/eirini-ci)
  - [eirini-release](https://github.com/cloudfoundry-incubator/eirini-release)

1. Create a feature branch for `eirini` and `eirini-release`
1. [Setup a personal development pipeline](https://github.com/cloudfoundry-incubator/eirini-ci#set-a-generic-development-pipeline)
1. Hack, commit, and push

   - Run all unit-tests and linters using the [`check-everything`](https://github.com/cloudfoundry-incubator/eirini/blob/master/scripts/check-everything.sh) script before pushing anything.

1. Look at the results:

   - Track the smoke-tests and CATs jobs in the CI
   - Check the `scf` namespace on your cluster using `kubectl get pods -n scf`
   - Login to `cf` and push an app. You can get the required api information using `helm status scf`.
   - Apps are usually pushed to the `eirini` namespace on your cluster

Changes to CAPI inkl. CloudController requires rebuilding scf templates and images, this doc is tbd.


