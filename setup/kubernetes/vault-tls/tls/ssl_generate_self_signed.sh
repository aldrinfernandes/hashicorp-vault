# Install Cloudflare utility
apt-get update && apt-get install -y curl &&
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl && \
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson && \
chmod +x /usr/local/bin/cfssl && \
chmod +x /usr/local/bin/cfssljson

#generate certificate
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname="vault,vault.vault.svc.cluster.local,vault.vault.svc,localhost,127.0.0.1,vault-0.vault-internal,vault-1.vault-internal,vault-2.vault-internal" \
  -profile=default \
  vault-csr.json | cfssljson -bare vault

#get values to make a secret
cat ca.pem | base64 | tr -d '\n'
cat vault.pem | base64 | tr -d '\n'
cat vault-key.pem | base64 | tr -d '\n'

#linux - make the secret automatically
cat <<EOF > ./server-tls-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: vault-server-tls
type: Opaque
data:
  vault-example.pem: $(cat vault.pem | base64 | tr -d '\n')
  vault-key.pem: $(cat vault-key.pem | base64 | tr -d '\n') 
  ca.pem: $(cat ca.pem | base64 | tr -d '\n')
EOF

# apply secrets to the kuberetes cluster
kubectl apply -f server-tls-secret.yaml
