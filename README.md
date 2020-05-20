# Terraforming Vault

Simple Demo for showcasing the possibility of filling your vault with terraform by creating a Vault PKi for a kubernetes CA. **Please note**, that the configs are not extensively tested but rather serve to showcase the terraforming of vault.

## Requirements

- [Vault](https://www.vaultproject.io/downloads) (tested with `1.3.4`)
- [Terraform](https://www.terraform.io/downloads.html) (tested with `v0.12.24`)

## Set up a test vault

```sh
export VAULT_TOKEN="token234"
export VAULT_ADDR='http://127.0.0.1:8200'
vault server -dev -dev-root-token-id=${VAULT_TOKEN} &>/dev/null &
```

## Terraform the vault

Apply the terraform from the root directory:

```sh
export TF_VAR_vault_address=${VAULT_ADDR}
terraform init
terraform apply --auto-approve
```

### Example usage: Issue a certificate for the api-server

After applying you should see an AppRole role_id in your output such as

```sh
...
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

approles = {
  "qa-cluster_master" = "<totally-secret-token>"
}
```

This role_id can be used to login to your vault and get a client token:

```sh
APPROLE_ID=$(terraform output -json approles | jq -r '."qa-cluster_master"')
CLIENT_TOKEN=$(curl -sf ${VAULT_ADDR}/v1/auth/approle/login -XPOST --data "{\"role_id\": \"${APPROLE_ID}\"}" | jq -er ".auth.client_token")
```

With this client_token we can then issue a certificate, in this case for kube-apiserver:

```sh
# issue a certificate
CERT_JSON=$(curl -fs --header "X-Vault-Token: ${CLIENT_TOKEN}" -XPOST --data @example-issue/apiserver.json ${VAULT_ADDR}/v1/clusters/qa-cluster/pkis/k8s/issue/master)
# get cert and private key from json response
jq -er ".data.certificate" <<< "$CERT_JSON" > apiserver_node1_cert.pem
jq -er ".data.private_key" <<< "$CERT_JSON" > apiserver_node1_key.pem
# you can retrieve the ca directly from vault
curl -fs -o ca.pem ${VAULT_ADDR}/v1/clusters/qa-cluster/pkis/k8s/ca/pem
```

and validate the certificates:

```bash
$ openssl verify -CAfile ca.pem apiserver_node1_cert.pem
apiserver_node1_cert.pem: OK
$ diff <(openssl pkey -in apiserver_node1_key.pem -pubout -outform pem | sha256sum) <(openssl x509 -in apiserver_node1_cert.pem -pubkey -noout -outform pem | sha256sum)
# no output when both match
```

## Clean up

```sh
kill $!
# you can safely remove the state after stopping the dev-vault server
rm terraform.tfstate
```
