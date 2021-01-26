# Eirini Release

This is a `helm` release for Project [Eirini](https://code.cloudfoundry.org/eirini). In a nutshell _Eirini_ is a Kubernetes backend for
Cloud Foundry, made in the effort to decouple Cloud Foundry from Diego, the only current option of a scheduler. It deploys CF apps
to a kube backend, using OCI images and Kube deployments.

## Installation

The following CFAR (Cloud Foundry Application Runtime) distributions deploy CF on top of Kubernetes and bundle Eirini with it:

- [cf-for-k8s](https://github.com/cloudfoundry/cf-for-k8s)
- [KubeCF](https://github.com/cloudfoundry-incubator/kubecf)

## Building the yaml release

To build the pure yaml files included in our release please run:

```shell
./scripts/render-templates.sh <system-namespace> <output-directory>
```

This will produce the yamls for all [eirini components](https://github.com/cloudfoundry-incubator/eirini/tree/65789e8ccb3f80986a34d9679733c53156a8e394#components) in separate directories. The components needed for cf-for-k8s are `core`, `events` and `workloads`.

## Security

### Security Overview

Of an overview of how secure Eirini is compared to other popular container runtimes please look at [this table](./docs/security-overview.md)

### Securing the Eirini Deployment

To learn about how you can use Kubernetes security primitives to make your deployment more secure, please take a look at our [Security Guidelines](docs/security-guidelines.md).

## Scalability

As of v1.5.0 a single instance of the eirini deployment can take a sustained load of 90 parallel desire LRP operations. A desire operation takes about 300ms on average when under load.

In order to better understand this result we have to state some condtitions that we assumed when performing the tests:

- Performing well under load means that the eirini server will respond in less than 30s.
- The tests were performed directly against the Eirini API (bypassing the cloud controller) and agains a sufficiently large cluster in order to make sure the eirini is the only bottleneck. So these results apply to eirini in isolation. The whole cf system will be as scalable as it's weakest subsystem.
- There results describe the throughput of eirini itself. Our measurements apply from the moment a desire request is placed to the moment a stateful set is created on Kubernetes. These are not scalability results for Kubernetes.

For details about high availability see [this doc](docs/scaling-and-ha.md).

## Differences with Diego

We are working hard towards feature parity with Diego, but still there are some differences in behaviour

### Environment variables

It is not possible to set environment variables containing `:` to your apps containers because of Kubernetes restrictions.

### Docker images running with the root user

By default Eirini does not allow docker images running with the root user. Diego allows this because the application runs in a separate user namespace, which is not supported in Kubernetes as of now. However, you can configure Eirini to allow such docker images - see [Security Guidelines](docs/security-guidelines.md#application-podsecuritypolicy) for more information.

### Task retries and parallelism

Tasks in Diego are run [at most once](https://github.com/cloudfoundry/diego-notes/blob/926024b/notes/lrp-task-states-and-transitions.md#task-states) and once completed you can determine whether they failed or not. In Eirini we run tasks as Jobs in Kubernetes with both `completions` and `parallelism` set to 1. However, [as per the Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#handling-pod-and-container-failures), there is no guarantee that the task won't be ran more than once.

## Troubleshooting

### Disk full on blobstore

If all the CF apps are running, it is safe to delete all files in `/var/vcap/store/shared/cc-droplets/sh/a2/` directory on the `blobstore-0` pod.
To do so, you can run this command:

```bash
kubectl exec -n <cf-system-namespace> blobstore-0 -c blobstore -- \
  /bin/sh -c 'rm -rf /var/vcap/store/shared/cc-droplets/sh/a2/sha256:*'
```

## Resources

- [Eirini Continuous Integration Pipeline](https://ci.eirini.cf-app.com/teams/main/pipelines/eirini-release)
