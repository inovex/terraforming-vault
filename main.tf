module "k8s-pki" {
  source = "./modules/cluster"

  clusters = {
    "qa-cluster" = {
      "ca_ttl"              = 14400
      "cert_ttl"            = 3600
      "apiserver_hostnames" = ["node1.inovex.de", "node2.inovex.de"]
    }
  }
  vault_address = var.vault_address
  organization  = "inovex GmbH"
  ou            = "Terraforming Task Force"
}
