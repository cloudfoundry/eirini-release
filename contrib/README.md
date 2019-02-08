# Community Tested Environments

## [Gardener](https://gardener.cloud)

- This has been tested with a single node Gardener-provisioned Kubernetes cluster deployed to Google Cloud.
- In addition to the configuration provided in the [Deploy](#deploy) section, amend `scf-config-values.yaml` with the following values:

    ```yaml
    env:

      # ...

      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537459332000100
      # needs to match the IP range of your K8s pods (see Gardener cluster YAML at
      # spec.cloud.gcp.networks.pods)
      BLOBSTORE_ACCESS_RULES: allow 100.96.0.0/11;

      # ...

      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537511390000100?thread_ts=1537509203.000100&cid=C8RU3BZ26
      GARDEN_ROOTFS_DRIVER: overlay-xfs
      GARDEN_APPARMOR_PROFILE: ""

      # ...

    opi:
      # see Gardener dashboard for your cluster -> Infrastructure -> Ingress
      # Domain; replace '*' with 'default'
      ingress_endpoint: <ingress-endpoint>

      # ...

    services:
      loadbalanced: true

    kube:
      # see https://cloudfoundry.slack.com/archives/C8RU3BZ26/p1537517553000100?thread_ts=1537509203.000100&cid=C8RU3BZ26
      # The internal (!) IP address assigned to the kube node pointed to by the
      # domain.
      external_ips:
      - <internal-ip>

      storage_class:
        persistent: "default"
        shared: "default"

      # ...
    ```
