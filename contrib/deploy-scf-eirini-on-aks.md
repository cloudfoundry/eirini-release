# Deploy SCF with Eirini on Microsoft Azure Kubernetes Service 

## Prerequisites
Install following tools to your remote admin machine:
* [Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/docs/using_helm/#installing-helm)

**Note** for a minimal installastion of Eirinin with SCF on AKS, you need 1 VM and 3 AKS agent nodes. 

## Installation
1. The SUSE Cloud Application Platform guidance: [Preparing Azure for SCF](https://www.suse.com/documentation/cloud-application-platform-1/book_cap_guides/data/cha_cap_depl-azure.html) describes the steps for installing SCF on AKS. To install **SCF with Eirini** on AKS, follow the section "Preparing Microsoft Azure for SUSE Cloud Application Platform" to complete following steps:
    1. [Prerequisites.](https://www.suse.com/documentation/cloud-application-platform-1/book_cap_guides/data/sec_cap_prereqs-azure.html)
    2. [Create resource group and AKS cluster.](https://www.suse.com/documentation/cloud-application-platform-1/book_cap_guides/data/sec_cap_create-aks-instance.html)  
    3. Install the `Helm` client locally and [create `Tiller`](https://www.suse.com/documentation/cloud-application-platform-1/book_cap_guides/data/sec_cap_tiller-service.html) on Kubernetes side.
    4. [Enable Swap Accounting](https://www.suse.com/documentation/cloud-application-platform-1/book_cap_guides/data/sec_cap_swap-accounting.html
), it's required on Azure.
    5. In this guideline, for testing purpose, we will use `xip.io` or `nip.io` rather than a real domain for the **DOMAIN** parameter. So we need to create Azure loadbalancer manually first. Use the following commands to create the required azure resources:  
      
        ```bash
        RGNAME=REPLACE_WITH_YOUR_OWN
        AKSNAME=REPLACE_WITH_YOUR_OWN

        export MCRGNAME=$(az aks show --resource-group $RGNAME --name $AKSNAME --query nodeResourceGroup -o json | jq -r '.')

        az network public-ip create \
          --resource-group $MCRGNAME \
          --name $AKSNAME-public-ip \
          --allocation-method Static

        az network lb create \
        --resource-group $MCRGNAME \
        --name $AKSNAME-lb \
        --public-ip-address $AKSNAME-public-ip \
        --frontend-ip-name $AKSNAME-lb-front \
        --backend-pool-name $AKSNAME-lb-back

        export NICNAMES=$(az network nic list --resource-group $MCRGNAME -o json | jq -r '.[].name')

        for i in $NICNAMES
        do
            az network nic ip-config address-pool add \
            --resource-group $MCRGNAME \
            --nic-name $i \
            --ip-config-name ipconfig1 \
            --lb-name $AKSNAME-lb \
            --address-pool $AKSNAME-lb-back
        done

        export CAPPORTS="80 443 4443 2222 2793 8443"

        for i in $CAPPORTS
        do
            az network lb probe create \
            --resource-group $MCRGNAME \
            --lb-name $AKSNAME-lb \
            --name probe-$i \
            --protocol tcp \
            --port $i 
            
            az network lb rule create \
            --resource-group $MCRGNAME \
            --lb-name $AKSNAME-lb \
            --name rule-$i \
            --protocol Tcp \
            --frontend-ip-name $AKSNAME-lb-front \
            --backend-pool-name $AKSNAME-lb-back \
            --frontend-port $i \
            --backend-port $i \
            --probe probe-$i 
        done

        az network lb rule list --resource-group $MCRGNAME --lb-name $AKSNAME-lb|grep -i port

        export AZNSG=$(az network nsg list --resource-group=$MCRGNAME -o json | jq -r '.[].name')
        export NSGPRI=200

        for i in $CAPPORTS
        do
            az network nsg rule create \
            --resource-group $MCRGNAME \
            --priority $NSGPRI \
            --nsg-name $AZNSG \
            --name $AKSNAME-$i \
            --direction Inbound \
            --destination-port-ranges $i \
            --access Allow
            export NSGPRI=$(expr $NSGPRI + 10)
        done
        ```

1. Create a `values.yaml` based on the following template, as the configuration file for the installation helm charts:
    
    ```yaml
    env:
      DOMAIN: REPLACE_LB_PUBLIC_IP.xip.io
      ENABLE_OPI_STAGING: false
      UAA_HOST: uaa.REPLACE_LB_PUBLIC_IP.xip.io
      UAA_PORT: 2793

    kube:
      auth: rbac
      external_ips: ["10.240.0.5", "10.240.0.6", "10.240.0.4"]
      storage_class:
        persistent: "managed-premium"
        shared: "shared"

    secrets:
      CLUSTER_ADMIN_PASSWORD: REPLACE
      UAA_ADMIN_CLIENT_SECRET: REPLACE
      BLOBSTORE_PASSWORD: REPLACE

    eirini:
      opi:
        use_registry_ingress: false
        #Enable if use_registry_ingress is set to 'true'
        #ingress_endpoint: kubernetes-cluster-ingress-endpoint
        #ingress_endpoint: <YOURS>.xip.io

      secrets:
        BITS_SERVICE_SECRET: REPLACE
        BITS_SERVICE_SIGNING_USER_PASSWORD: REPLACE
        BLOBSTORE_PASSWORD: REPLACE

      kube:
        external_ips:
        - "10.240.0.5"
    ```
    
    **NOTES**: 
    + The above template may still evolving, check the latest config [here](https://github.com/cloudfoundry-incubator/eirini-release/blob/master/values.yaml).
    + Get the IP address of loadbalancer which created in step #1, replace *REPLACE_LB_PUBLIC_IP* with it in `values.yaml`
    + Overwrite all string called *REPLACE* with your own values in `values.yaml`.
    + ["10.240.0.5", "10.240.0.6", "10.240.0.4"] are the default IP addresses of 3 AKS node agents, you can modify as needed.

1. Make the Eirini helm repository available to helm:

    ```bash
    helm repo add eirini https://cloudfoundry-incubator.github.io/eirini-release
    helm repo update
    ```

1. Install UAA:

    ```bash
    helm install eirini/uaa --namespace uaa --name uaa --values <your-values.yaml>
    ```

1. Use the following command to verify that every UAA pod is `Running` or `Completed`:
    
    ```bash
    watch kubectl get pods -n uaa
    ```

1. Export the UAA ca certificate using the following commands:

    ```bash
    SECRET=$(kubectl get pods --namespace uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
    CA_CERT="$(kubectl get secret $SECRET --namespace uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
    ```

1. Install SCF with Eirini:

    ```bash
    helm install eirini/cf --namespace scf --name scf --set "secrets.UAA_CA_CERT=${CA_CERT}" --values <your-values.yaml>
    ```

1. Use the following command to verify that every CF control plane pod is `Running` and `Completed`:

    ```bash
    watch kubectl get pods -n scf
    ```

1. The `bits` pod is expected to run into failure since the latest bits-service [image](https://hub.docker.com/r/flintstonecf/bits-service/tags) has removed the [eirinifs](https://github.com/cloudfoundry-incubator/eirinifs) layer. It's a base layer for all CF apps that run on Kubernetes.

1. Use the following command to delete `bits` pod temporarily:
    
    ```bash
    kubectl scale deployment/bits -n scf --replicas=0
    ```

1. Use the following command to update image for `bits` pod:
    
    ```bash
    kubectl set image deployment/bits bits=flintstonecf/bits-service:2.25.0-dev.7 -n scf
    ```

1. Use the following command to edit ConfigMap for `bits` pod:
    
    ```bash
    kubectl edit configmap bits -n scf
    ```

    + ensure
    
      ```yaml
      enable_registry: true
      ```
    
    + then add `registry_endpoint` as below:
    
      ```yaml
      apiVersion: v1
      data:
        bits-config-key: |
          logging:
            level: debug
          private_endpoint: "https://bits.scf.svc.cluster.local"
          public_endpoint: https://bits.10.240.0.5.nip.io
          registry_endpoint: "https://registry.10.240.0.5.nip.io"
          ...
      ```

1. Use the following command to let `bits` pod running again:
    
    ```bash
    kubectl scale deployment/bits -n scf --replicas=1
    ```

1. Watch the `bits` pod is `Running`.

