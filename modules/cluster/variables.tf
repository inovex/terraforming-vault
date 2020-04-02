variable "clusters" {
  type        = map(object({ max_cert_ttl = number }))
  description = "Name of the kubernetes cluster to create a PKI for"
}

variable "vault_address" {
  type = string
}
