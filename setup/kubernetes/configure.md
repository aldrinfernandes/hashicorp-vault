# Configure Vault

## Configure Vault for Kubernetes

1. Exec into leader(vault-0 mostly) pod
    ```
    kubectl exec -it -n vault vault-0 -- sh
    ```
2. Login into Vault
    ```
    vault login
    ```
    **Note: Don't use Initial Root Token in Production**
3. Enable Kubernetes authentication
    ```
    vault auth enable -path non-prod kubernetes
    ```
    Path is optional<br>
    Output:
        Success! Enabled kubernetes auth method at: non-prod/

4. Configure the Kubernetes authentication method to use location of the Kubernetes API.
    ```
    vault write auth/non-prod/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
    ```
    Output:
        Success! Data written to: auth/non-prod/config

5. Enable kv-v2 Secrets Engine
    ```
    vault secrets enable -path=kvv2 kv-v2
    ```
    Output:
        Success! Enabled the kv-v2 secrets engine at: kvv2/
6. Creating A New Access Policy
    ```
    vault policy write dev_policy - <<EOF
    path "kvv2/data/dev" {
    capabilities = ["read"]
    }
    EOF
    ```
    Output:
        Success! Uploaded policy: dev_policy
7. Role to be used to access Vault
    ```
    vault write auth/non-prod/role/dev\
    bound_service_account_names=dev-user \
    bound_service_account_namespaces=dev \
    policies=dev_policy\
    audience=vault \
    ttl=8760h
    ```
    Output:
        Success! Data written to: auth/non-prod/role/dev
8. Add secret
    ```
    vault kv put kvv2/dev username="some-username" password="some-password"
    ```