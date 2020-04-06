# Terraforming Vault

Simple Demo for showcasing the possibility of filling your vault with terraform by creating a kubernetes CA.

## Set up a test vault

```sh
export VAULT_TOKEN="token234"
export VAULT_ADDR='http://127.0.0.1:8200'
vault server -dev -dev-root-token-id=${VAULT_TOKEN} >/dev/null &
```

## Terraform the vault

Apply the terraform from the root directory (might require a `terraform init` beforehand):

```sh
export TF_VAR_vault_address=${VAULT_ADDR}
terraform apply --auto-approve
```

### Example usage: Issue a certificate for the api-server

```sh
# issue a certificate
JSON=$(curl --header "X-Vault-Token: ${VAULT_TOKEN}" -XPOST --data @example-issue/apiserver.json http://127.0.0.1:8200/v1/clusters/qa-cluster/pkis/k8s/issue/master)
# get cert and private key from json response
jq -r ".data.certificate" <<< "$JSON" > apiserver_node1_cert.pem
jq -r ".data.private_key" <<< "$JSON" > apiserver_node1_key.pem
# you can retrieve the ca directly from vault
curl -o ca.pem http://127.0.0.1:8200/v1/clusters/qa-cluster/pkis/k8s/ca
```

## Clean up

```sh
pkill vault
# you can safely remove the state after stopping the dev-vault server
rm terraform.tfstate
```
