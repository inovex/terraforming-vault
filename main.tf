module "k8s-pki" {
  source = "./modules/cluster"

  clusters = {
    "qa-cluster" = {
      "max_cert_ttl" = 3600
    }
  }
  vault_address = var.vault_address
}
