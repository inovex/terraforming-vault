variable "clusters" {
  type        = map(object({ cert_ttl = number, ca_ttl = number, apiserver_hostnames = list(string) }))
  description = "Name of the kubernetes cluster to create a PKI for"
}

variable "vault_address" {
  type = string
}

variable "organization" {
  type = string
}

variable "ou" {
  type = string
}
