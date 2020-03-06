## Service Account

When an app is pushed with Eirini, the pods are assigned the default Service Account in `opi.namespace`. By default, when the cluster is deployed with `RBAC` authentication method, that Service Account should not have any read/write permissions to the Kubernetes API. Since `RBAC` is preferred to `ABAC`, we recommend using the former.

## Network policies

Apps pushed by Eirini currently cannot be accessed directly from another app container. This is accomplished by creating a [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resource in the namespace in which Eirini deploys apps.

In order to use network policies in your cluster, you must use a compatible container network plug-in, otherwise creating a `NetworkPolicy` resource will have no effect.

Both [IKS](https://cloud.ibm.com/docs/containers?topic=containers-network_policies) (is automatically setup) and [GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy#enabling_network_policy_enforcement) (has to be enabled) support a network plug-in called [Calico](https://www.projectcalico.org/), which supports defining network policies.

For other implementations of the Kubernetes networking model, take a look [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model). Keep in mind that not all implementations support defining network polcies (e.g. Flannel). For a more detailed comparison between different plugins, take a look [here](https://docs.google.com/spreadsheets/d/1qCOlor16Wp5mHd6MQxB5gUEQILnijyDLIExEpqmee2k/edit#gid=0) (not maintained by us).

### Securing SCF endpoints

It is not possible to do it with native Kubernetes network policies. In order to achieve this, the CNI plugin can be used directly. If you're using [Calico](https://www.projectcalico.org/) on IBMCloud, you can run the following command:

```bash
calicoctl apply --config $CALICOCNF -f - <<EOF
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: deny-scf-access
  namespace: eirini
spec:
  types:
  - Egress
  egress:
  - action: Deny
    source:
      selector: source_type == 'APP'
    destination:
      namespaceSelector: name == 'scf'
  - action: Allow
EOF
```

You can use [this](https://www.ibm.com/cloud/blog/configure-calicoctl-for-ibm-cloud-kubernetes-service) guide to export `$CALICOCNF` on IBM Cloud.

Note that GKE does not currently support creating custom Calico network policies.

### Securing Kubernetes API Endpoint

The Kubernetes API is available in all pods by default at `https://kubernetes.default`. Eirini does not mount
service account credentials to the pod and uses default service account in the namespace. This prevents Eirini pods from using Kubernetes API.
To completely disallow access to this from application instances, you'd need to apply this network policy:

```yaml
apiVersion: extensions/v1beta1
kind: NetworkPolicy
metadata:
  name: eirini-egress-policy
  namespace: eirini
spec:
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - <API IP Address>/32
  podSelector: {}
  policyTypes:
  - Egress
```

You can get IP address of the master by running `kubectl get endpoints` command. If there are multiple Kubernetes API nodes, IP address
of each of them would need to be specified in the `except` array.
