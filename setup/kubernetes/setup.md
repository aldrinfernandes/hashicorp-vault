# HashiCorp Vault : Kubernetes with HA

## Requirements
1. Kubernetes cluster.
2. Kubectl and Helm installed.

## Steps
1. Add HashiCorp Vault repository to Helm.
2. Install Vault.
3. Unseal Vault and join Vault nodes.

## Step 1 : Adding HashiCorp Vault repository to Helm
If you don't have helm install follow the [Helm docs](https://helm.sh/docs/intro/install/) to install it.<br>
```helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm search repo hashicorp/vault
```
NOTE: At the time of installation, Vault helm chart version was 0.23.0 and Vault version was 1.12.1

## Step 2: Installing Vault on cluster
### Without TLS
If there is no external ingress to Vault, we can use it without TLS. But TLS is highly recommended.
```
helm install vault hashicorp/vault -n vault --create-namespace --version=0.23.0 --set='server.ha.enabled=true' --set='server.ha.raft.enabled=true'
```
server.ha.raft.enabled=true : is used to enable [raft storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) 

### With TLS
1. Generate certificate [ssl_generate_self_signed.sh](https://github.com/aldrinfernandes/hashicorp-vault/blob/main/setup/kubernetes/vault-tls/tls/ssl_generate_self_signed.sh)
2. Installing Vault by overriding defaults.<br>
   ```
   helm install -n vault vault -n vault --create-namespace hashicorp/vault -f setup/kubernetes/vault-tls/helm-overrides/vault-values.yaml.yaml
   ```

## Step 3: Unseal Vault and join Vault nodes.

### Initialize Vault(without TLS)
1. Exec into vault-0 pod
   ```
   kubectl exec -ti -n vault vault-0 -- vault operator init
   ```
   Output:
   ```
    Unseal Key 1: KEY_1
    Unseal Key 2: KEY_2
    Unseal Key 3: KEY_3
    Unseal Key 4: KEY_4
    Unseal Key 5: KEY_5

    Initial Root Token: ROOT_TOKEN

    Vault initialized with 5 key shares and a key threshold of 3. Please securely
    distribute the key shares printed above. When the Vault is re-sealed,
    restarted, or stopped, you must supply at least 3 of these keys to unseal it
    before it can start servicing requests.

    Vault does not store the generated root key. Without at least 3 keys to
    reconstruct the root key, Vault will remain permanently sealed!

    It is possible to generate new unseal keys, provided you have a quorum of
    existing unseal keys shares. See "vault operator rekey" for more information.
    ```
2. Unseal vault-0, pod, we need to provide any 3 of the 5 key from previous step to unseal vault
   ```
    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_1
        Key                Value
        ---                -----
        Seal Type          shamir
        Initialized        true
        Sealed             true
        Total Shares       5
        Threshold          3
        Unseal Progress    1/3
        Unseal Nonce       b821daec-c4db-5acf-40d6-54f2945a2d93
        Version            1.12.1
        Build Date         2022-10-27T12:32:05Z
        Storage Type       raft
        HA Enabled         true

    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_2
        Key                Value
        ---                -----
        Seal Type          shamir
        Initialized        true
        Sealed             true
        Total Shares       5
        Threshold          3
        Unseal Progress    2/3
        Unseal Nonce       b821daec-c4db-5acf-40d6-54f2945a2d93
        Version            1.12.1
        Build Date         2022-10-27T12:32:05Z
        Storage Type       raft
        HA Enabled         true

    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_3
        Key                     Value
        ---                     -----
        Seal Type               shamir
        Initialized             true
        Sealed                  false
        Total Shares            5
        Threshold               3
        Version                 1.12.1
        Build Date              2022-10-27T12:32:05Z
        Storage Type            raft
        Cluster Name            vault-cluster-e974f537
        Cluster ID              ffc2f0c9-e9e6-4b47-8a81-c96180515772
        HA Enabled              true
        HA Cluster              https://vault-0.vault-internal:8201
        HA Mode                 active
        Active Since            2024-02-20T12:46:13.923731106Z
        Raft Committed Index    36
        Raft Applied Index      36
    ```
    When the 'Sealed' key shows false vault-0 is unsealed
3. Raft join vault-1 to vault-0 and unseal it
   ```
   kubectl exec -ti -n vault vault-1 -- vault operator raft join http://vault-0.vault.vault-internal:8200
   ```
   if the above command fails try the below command
   ```
   kubectl exec -ti -n vault vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
   ```
   Unseal vault-1 similar to step-2 for vault-0
   ```
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_1
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_2
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_3
   ```
   Vault-1 is now unsealed
4. Raft join vault-2 to vault-0 and unseal it.
   ```
   kubectl exec -ti -n vault vault-2 -- vault operator raft join http://vault-0.vault.vault-internal:8200
   ```
   if the above command fails try the below command
   ```
   kubectl exec -ti -n vault vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
   ```
   Unseal vault-2 similar to step-2 for vault-0
   ```
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_1
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_2
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_3
   ```
   Vault-2 is now unsealed. Validate the same using vault-0
   ```
    kubectl exec -ti -n vault vault-0 -- vault operator raft list-peers
   ```
   
### Initialize Vault(with TLS)
1. Exec into vault-0 pod
   ```
   kubectl exec -ti -n vault vault-0 -- vault operator init
   ```
   Output:
   ```
    Unseal Key 1: KEY_1
    Unseal Key 2: KEY_2
    Unseal Key 3: KEY_3
    Unseal Key 4: KEY_4
    Unseal Key 5: KEY_5

    Initial Root Token: ROOT_TOKEN

    Vault initialized with 5 key shares and a key threshold of 3. Please securely
    distribute the key shares printed above. When the Vault is re-sealed,
    restarted, or stopped, you must supply at least 3 of these keys to unseal it
    before it can start servicing requests.

    Vault does not store the generated root key. Without at least 3 keys to
    reconstruct the root key, Vault will remain permanently sealed!

    It is possible to generate new unseal keys, provided you have a quorum of
    existing unseal keys shares. See "vault operator rekey" for more information.
    ```
2. Unseal vault-0, pod, we need to provide any 3 of the 5 key from previous step to unseal vault
   ```
    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_1
        Key                Value
        ---                -----
        Seal Type          shamir
        Initialized        true
        Sealed             true
        Total Shares       5
        Threshold          3
        Unseal Progress    1/3
        Unseal Nonce       b821daec-c4db-5acf-40d6-54f2945a2d93
        Version            1.12.1
        Build Date         2022-10-27T12:32:05Z
        Storage Type       raft
        HA Enabled         true

    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_2
        Key                Value
        ---                -----
        Seal Type          shamir
        Initialized        true
        Sealed             true
        Total Shares       5
        Threshold          3
        Unseal Progress    2/3
        Unseal Nonce       b821daec-c4db-5acf-40d6-54f2945a2d93
        Version            1.12.1
        Build Date         2022-10-27T12:32:05Z
        Storage Type       raft
        HA Enabled         true

    kubectl exec -ti -n vault vault-0 -- vault operator unseal KEY_3
        Key                     Value
        ---                     -----
        Seal Type               shamir
        Initialized             true
        Sealed                  false
        Total Shares            5
        Threshold               3
        Version                 1.12.1
        Build Date              2022-10-27T12:32:05Z
        Storage Type            raft
        Cluster Name            vault-cluster-e974f537
        Cluster ID              ffc2f0c9-e9e6-4b47-8a81-c96180515772
        HA Enabled              true
        HA Cluster              https://vault-0.vault-internal:8201
        HA Mode                 active
        Active Since            2024-02-20T12:46:13.923731106Z
        Raft Committed Index    36
        Raft Applied Index      36
    ```
    When the 'Sealed' key shows false vault-0 is unsealed
3. Raft join vault-1 to vault-0 and unseal it
   ```
   kubectl exec -ti -n vault vault-1 -- sh
   vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-server-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-server-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-server-tls/vault.key)" https://vault-0.vault.vault-internal:8200
   ```
   if the above command fails try the below command
   ```
   kubectl exec -ti -n vault vault-1 -- sh
   vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-server-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-server-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-server-tls/vault.key)"  https://vault-0.vault-internal:8200
   ```
   Unseal vault-1 similar to step-2 for vault-0
   ```
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_1
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_2
   kubectl exec -ti -n vault vault-1 -- vault operator unseal KEY_3
   ```
   Vault-1 is now unsealed
4. Raft join vault-2 to vault-0 and unseal it.
   ```
   kubectl exec -ti -n vault vault-2 -- sh
   vault operator raft join -address=https://vault-2.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-server-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-server-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-server-tls/vault.key)" https://vault-0.vault.vault-internal:8200
   ```
   if the above command fails try the below command
   ```
   vault operator raft join -address=https://vault-2.vault-internal:8200 -leader-ca-cert="$(cat /vault/userconfig/vault-server-tls/vault.ca)" -leader-client-cert="$(cat /vault/userconfig/vault-server-tls/vault.crt)" -leader-client-key="$(cat /vault/userconfig/vault-server-tls/vault.key)" https://vault-0.vault-internal:8200
   ```
   Unseal vault-2 similar to step-2 for vault-0
   ```
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_1
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_2
   kubectl exec -ti -n vault vault-2 -- vault operator unseal KEY_3
   ```
   Vault-2 is now unsealed

## Reference
1. [Installing Vault on Kubernetes](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator)
2. [Raft Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft)
3. [Vault installation to minikube via Helm with TLS enabled](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls)