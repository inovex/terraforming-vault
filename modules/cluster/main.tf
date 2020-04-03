# creates CAs that follow the kubernetes best practices https://kubernetes.io/docs/setup/best-practices/certificates/#configure-certificates-manually

## k8s
resource "vault_mount" "k8s_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/k8s"
  max_lease_ttl_seconds = each.value.max_cert_ttl
}

resource "vault_pki_secret_backend_root_cert" "k8s_ca" {
  depends_on = [vault_mount.k8s_pki]

  for_each = var.clusters
  backend  = vault_mount.k8s_pki[each.key].path

  type                 = "internal"
  common_name          = "kubernetes-ca"
  ttl                  = "315360000"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "Terraforming Task Force"
  organization         = "inovex GmbH"
}

resource "vault_pki_secret_backend_config_urls" "k8s_config_urls" {
  for_each = var.clusters
  backend  = vault_mount.k8s_pki[each.key].path

  issuing_certificates = ["${var.vault_address}/v1/${vault_mount.k8s_pki[each.key].path}/ca"]
}

## etcd
resource "vault_mount" "etcd_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/etcd"
  max_lease_ttl_seconds = each.value.max_cert_ttl
}

resource "vault_pki_secret_backend_root_cert" "etcd_ca" {
  depends_on = [vault_mount.etcd_pki]

  for_each = var.clusters
  backend  = vault_mount.etcd_pki[each.key].path

  type                 = "internal"
  common_name          = "etcd-ca"
  ttl                  = "315360000"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "Terraforming Task Force"
  organization         = "inovex GmbH"
}

resource "vault_pki_secret_backend_config_urls" "etcd_config_urls" {
  for_each = var.clusters
  backend  = vault_mount.etcd_pki[each.key].path

  issuing_certificates = ["${var.vault_address}/v1/${vault_mount.etcd_pki[each.key].path}/ca"]
}
