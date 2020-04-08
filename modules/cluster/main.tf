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

resource "vault_pki_secret_backend_role" "etcd_master_role" {
  for_each = var.clusters
  backend  = vault_mount.etcd_pki[each.key].path

  name           = "master"
  allow_any_name = true
  allow_ip_sans  = true

  max_ttl = each.value.cert_ttl
  ttl     = each.value.cert_ttl

  allowed_domains = [
    "kube-etcd",
    "kube-etcd-peer",
    "kube-etcd-healthcheck-client",
    "kube-apiserver-etcd-client"
  ]

  allowed_uri_sans = concat(each.value.apiserver_hostnames, ["localhost"])

  key_usage     = ["DigitalSignature", "KeyEncipherment"]
  ext_key_usage = ["ServerAuth", "ClientAuth"]
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

  allowed_uri_sans = concat(each.value.apiserver_hostnames, [
    "kubernetes.default.svc.cluster.local",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc",
    "kubernetes.default",
    "kubernetes",
  ])

  key_usage = ["DigitalSignature", "KeyEncipherment"]
  # ServerAuth is required for kube-apiserver cert, ClientAuth for kube-apiserver-kubelet-client
  ext_key_usage = ["ServerAuth", "ClientAuth"]
}

## kubernetes-front-proxy-ca
resource "vault_mount" "k8s_front_proxy_pki" {
  for_each = var.clusters

  type                  = "pki"
  path                  = "clusters/${each.key}/pkis/k8s-front-proxy"
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

## policy and authrole for issuing certs
resource "vault_policy" "master_role_access" {
  for_each = var.clusters

  name = "${each.key}_master"

  policy = <<EOT
path "${vault_mount.etcd_pki[each.key].path}/issue/${vault_pki_secret_backend_role.etcd_master_role[each.key].name}" {
  capabilities = ["create", "update"]
}
path "${vault_mount.k8s_pki[each.key].path}/issue/${vault_pki_secret_backend_role.k8s_master_role[each.key].name}" {
  capabilities = ["create", "update"]
}
path "${vault_mount.k8s_front_proxy_pki[each.key].path}/issue/${vault_pki_secret_backend_role.k8s_front_proxy_master_role[each.key].name}" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_approle_auth_backend_role" "master_authrole" {
  for_each = var.clusters
  backend  = var.approle_path

  role_name = "${each.key}_master"
  # we do not use a secret id and instead bind localhost as cidr for demo purposes
  bind_secret_id    = false
  token_bound_cidrs = ["127.0.0.1/32"]
  token_policies    = [vault_policy.master_role_access[each.key].name]
}
