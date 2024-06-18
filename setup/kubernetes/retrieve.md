# Get Secrets from Vault

## Way to get secret from Vault
1. Vault-operator(similar to Kubernetes secrets).
2. Inject secrets using agent sidecar.

## Vault Operator

The vault operator id deployed in it's own namespace other than the one in which vault is deployed and the other where the application is deployed. This approach is similar to how we have secrets in Kubernetes.

1. Install Operator using Helm in a new namespace vault-secrets-operator-system.
    ```
    helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault-secrets-operator-system --create-namespace --values setup/kubernetes/vault-operator/vault-operator-values.yaml
    ```
2. Configure application namespace connect with Vault using the Vault operator
    1. Deploy CRD(Custom Resource Definition) of VaultConnection to connect with Vault.
        ```
        kubectl apply -f hashicorp_vault/kubernetes/prod-setup/connection.yaml -n dev
        ```
    2. Deploy the service account 'dev-user' in the namespace dev required by the CRD VaultAuth to authenticate to Vault
        ```
        kubectl apply -f setup/kubernetes/vault-operator/service_account.yaml -n dev
        ```
    3. Deploy CRD for VaultAuth to authenticate connection with vault
        ```
        kubectl apply -f setup/kubernetes/vault-operator/dev-vault-auth-static.yaml -n dev
        ```
    4. Deploy CRD for getting secrets from Vault as a Kubernetes secret in namespace
        ```
        kubectl apply -f setup/kubernetes/vault-operator/dev-kv.yaml -n dev
        ```
    5. Validated secret in namespace with the name as mentioned in spec.destination.name
        ```
        kubectl get secrets dev-secret-kv -n dev -o yaml
        ```
    6. Deploy application and validated secrets 
       Using shell command env
        ```
        kubectl exec \
      $(kubectl get pod -l app=basic-secret -o jsonpath="{.items[0].metadata.name}") \
      -c app -- env
        ```
        Or by checking directory 
        ```
        kubectl exec \
      $(kubectl get pod -l app=basic-secret -o jsonpath="{.items[0].metadata.name}") \
      -c app -- cat /etc/my-app
        ```

## Inject secrets using agent sidecar

Injecting secrets into Kubernetes pods via Vault Agent containers, this is the easiest way to retrieve secrets in Vault.

1. Create service account in dev namespace
    ```
    kubectl apply -f setup/kubernetes/vault-agent-sidecar/service_account.yaml -n dev
    ```
2. Deploy application to kubernetes
    ```
    kubectl apply -f setup/kubernetes/vault-agent-sidecar/deployment.yaml -n dev
    ```
    **Note: Need to add the annotations vault.hashicorp.com**
3. Exec into the pod and check location '/vault/secrets/database-config.txt' to validate the secrets
    ```
    kubectl exec \
      $(kubectl get pod -l app=basic-secret -o jsonpath="{.items[0].metadata.name}") \
      -c app -- cat /vault/secrets/database-config.txt
    ```
    

## References
1. [The Vault Secrets Operator on Kubernetes.](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator)
2. [Secret Management](https://github.com/martinnirtl/talks/tree/main/mirantis/labs/secret_management)
3. [Injecting secrets into Kubernetes pods via Vault Agent containers.](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar)