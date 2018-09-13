# Eirini Kube-Release

**What is that?**

This directory provides everything you need to build the OPI Docker imanges and in addition it provides a Kubernetes helm deployment, which you can use to easily `helm deploy ./eirini`.

**Why do I need that? -> Because it's awesome!**

The simple reason why we have it is, because it's not a big deal and it speeds up our development by far. Instead of deploying the whole CF beast - including OPI as VM - we simply deploy OPI as container in Kuberenetes and point CF to it. Testing a new version is nothing more than...

- `docker build`
- `docker push`
- `helm install`

...and it takes just minutes.

## Helm

### Prereqs

Beside a running Bosh (Bosh-Lite) and a Kubernetes cluster you should have:

- [helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)

#### Deploy Eirini

1. Copy the Kubernetes config file to `helm/eirini/configs/` directory as `kube.yaml` (name is important)

```
$ kubectl config view --flatten > `helm/eirini/configs/kube.yaml
```

1. Create `helm/eirini/configs/opi.yaml` using the following template:

```yaml
opi:
  kube_config: "/workspace/jobs/opi/config/kube.conf"
  kube_namespace: "<target-kubernetes-namespace>"
  kube_endpoint: "<target-kubernetes-api-endpoint>"
  nats_password: "<cf-nats-password>"
  nats_ip: "<cf-nats-ip>"
  api_endpoint: "<cf-api-endpoint>"
  cf_username: "<cf-username>"
  cf_password: "<cf-password>"
  external_eirini_address: "<eirini-registry-host>:<port>"
  eirini_address: "<eirini-opi-host>:<port>"
  skip_ssl_validation: <true | false>
  insecure_skip_verify: <true | false>
```

- `kube_namespace`: Namespace where CF apps are going to be deployed by OPI
- `nats_password & nats_ip`: Nats information can be found in [cf-deployment](https://github.com/cloudfoundry/cf-deployment) manifest and `deployment-vars.yml`
- `external_eirini_address`: Host:Port for Eirini registry, usually on port `8080`
- `eirini_address`: Host:Port for Eirini opi, usually on port `8085`

1. Install the chart using the following `helm` command:

```bash
$ helm install --set-string ingress.opi.host="eirini-opi.<kube-ingress-endpoint>",ingress.registry.host="eirini-registry.<kube-ingress-endpoint>" ./helm/eirini
```

If your Kube-Cluster has `Role Based Access Control (RBAC)` enabled, you should enable it with [`rbac.enabled=true`]:

```bash
$ helm install --set-string ingress.opi.host="eirini-opi.<kube-ingress-endpoint>",ingress.registry.host="eirini-registry.<kube-ingress-endpoint>",rbac.enabled=true ./helm/eirini
```

That's it :)

## Docker

### Prereqs

- Docker
- Init Submodules
- Go to `src/code.cloudfoundry.org/eirini/launcher/buildpackapplifecycle/launcher/package.go` and remove the comment

### Create Docker Images

1. Run `docker/generate-docker-image.sh`
