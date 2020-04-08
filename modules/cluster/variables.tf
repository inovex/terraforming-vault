variable "clusters" {
  type        = map(object({ cert_ttl = number, ca_ttl = number, apiserver_hostnames = list(string) }))
  description = "configs of the kubernetes cluster to create a PKI for mapped on their names"
}

variable "approle_path" {
  type        = string
  description = "path of the vault approle auth backend to create node authroles in"
}

variable "vault_address" {
  type        = string
  description = "address of the vault instance used to retrieve the PKI CAs"
}

variable "organization" {
  type        = string
  description = "organization for generated CAs"
}

variable "ou" {
  type        = string
  description = "ou for generated CAs"
}
