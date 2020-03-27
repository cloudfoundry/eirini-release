# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini). In a nutshell *Eirini* is a Kubernetes backend for 
Cloud Foundry, made in the effort to decouple Cloud Foundry from Diego, the only current option of a scheduler. . It deploys CF apps 
to a kube backend, using OCI images and Kube deployments.

## Installation

There are two ways to install Cloud Foundry with Eirini enabled:

* [cf-for-k8s](https://github.com/cloudfoundry/cf-for-k8s)
* [KubeCF](https://github.com/cloudfoundry-incubator/kubecf)

## Security

### Security Overview

Of an overview of how secure Eirini is compared to other popular container runtimes please look at [this table](./docs/security-overview.md)

### Securing the Eirini Deployment

To learn about how you can use Kubernetes security primitives to make your deployment more secure, please take a look at our [Security Guidelines](docs/security-guidelines.md).

## Differences with Diego

We are working hard towards feature parity with Diego, but still there are some differences in behaviour

### Environment variables
It is not possible to set environment variables containing `:` to your apps containers because of Kubernetes restrictions. 

### Docker images runnig with the root user
By default Eirini does not allow docker images running with the root user. Diego allows this because the application runs in a separate user namespace, which is not supported in Kubernetes as of now. However, you can configure Eirini to allow such docker images - see [Security Guidelines](docs/security-guidelines.md#application-podsecuritypolicy) for more information.

## Troubleshooting

### Disk full on blobstore

If all the CF apps are running, it is safe to delete all files in `/var/vcap/store/shared/cc-droplets/sh/a2/` directory on the `blobstore-0` pod.
To do so, you can run this command:

```bash
kubectl exec -n <scf-namespace> blobstore-0 -c blobstore -- \
  /bin/sh -c 'rm -rf /var/vcap/store/shared/cc-droplets/sh/a2/sha256:*'
```

## Resources

* [SCF documentation](https://github.com/SUSE/scf/wiki/How-to-Install-SCF#deploy-using-helm)
* [Eirini Continuous Integration Pipeline](https://ci.eirini.cf-app.com/teams/main/pipelines/eirini-release)
