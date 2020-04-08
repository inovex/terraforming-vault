# creates CAs that follow the kubernetes best practices https://kubernetes.io/docs/setup/best-practices/certificates/#configure-certificates-manually

## etcd-ca
resource "vault_mount" "etcd_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/etcd"
  max_lease_ttl_seconds = each.value.ca_ttl
}

resource "vault_pki_secret_backend_root_cert" "etcd_ca" {
  depends_on = [vault_mount.etcd_pki]

  for_each = var.clusters
  backend  = vault_mount.etcd_pki[each.key].path

  type                 = "internal"
  common_name          = "etcd-ca"
  ttl                  = each.value.ca_ttl
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = var.ou
  organization         = var.organization
}

resource "vault_pki_secret_backend_config_urls" "etcd_config_urls" {
  for_each = var.clusters
  backend  = vault_mount.etcd_pki[each.key].path

  issuing_certificates = ["${var.vault_address}/v1/${vault_mount.etcd_pki[each.key].path}/ca"]
}

## kubernetes-ca
resource "vault_mount" "k8s_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/k8s"
  max_lease_ttl_seconds = each.value.ca_ttl
}

resource "vault_pki_secret_backend_root_cert" "k8s_ca" {
  depends_on = [vault_mount.k8s_pki]

  for_each = var.clusters
  backend  = vault_mount.k8s_pki[each.key].path

  type                 = "internal"
  common_name          = "kubernetes-ca"
  ttl                  = each.value.ca_ttl
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = var.ou
  organization         = var.organization
}

resource "vault_pki_secret_backend_config_urls" "k8s_config_urls" {
  for_each = var.clusters
  backend  = vault_mount.k8s_pki[each.key].path

  issuing_certificates = ["${var.vault_address}/v1/${vault_mount.k8s_pki[each.key].path}/ca"]
}

resource "vault_pki_secret_backend_role" "k8s_master_role" {
  for_each = var.clusters
  backend  = vault_mount.k8s_pki[each.key].path

  name           = "master"
  allow_any_name = true
  allow_ip_sans  = true

  max_ttl = each.value.cert_ttl
  ttl     = each.value.cert_ttl

  allowed_domains = [
    "kube-apiserver",
    "kube-apiserver-kubelet-client"
  ]

  allowed_uri_sans = each.value.apiserver_hostnames

  key_usage = ["DigitalSignature", "KeyEncipherment"]
  # ServerAuth is required for kube-apiserver cert, ClientAuth for kube-apiserver-kubelet-client
  ext_key_usage = ["ServerAuth", "ClientAuth"]
}

## 	kubernetes-front-proxy-ca
resource "vault_mount" "k8s_front_proxy_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/k8s_front_proxy"
  max_lease_ttl_seconds = each.value.ca_ttl
}

resource "vault_pki_secret_backend_root_cert" "k8s_front_proxy_ca" {
  depends_on = [vault_mount.k8s_front_proxy_pki]

  for_each = var.clusters
  backend  = vault_mount.k8s_front_proxy_pki[each.key].path

  type                 = "internal"
  common_name          = "kubernetes-front-proxy-ca"
  ttl                  = each.value.ca_ttl
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = var.ou
  organization         = var.organization
}

resource "vault_pki_secret_backend_config_urls" "k8s_front_proxy_config_urls" {
  for_each = var.clusters
  backend  = vault_mount.k8s_front_proxy_pki[each.key].path

  issuing_certificates = ["${var.vault_address}/v1/${vault_mount.k8s_front_proxy_pki[each.key].path}/ca"]
}

resource "vault_pki_secret_backend_role" "k8s_front_proxy_master_role" {
  for_each = var.clusters
  backend  = vault_mount.k8s_front_proxy_pki[each.key].path

  name           = "master"
  allow_any_name = true

  max_ttl = each.value.cert_ttl
  ttl     = each.value.cert_ttl

  key_usage     = ["DigitalSignature", "KeyEncipherment"]
  ext_key_usage = ["ClientAuth"]
}
