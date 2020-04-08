output "master_approles" {
  #value = vault_approle_auth_backend_role.master_authrole["qa-cluster"].role_id
  value = {
    for approle in vault_approle_auth_backend_role.master_authrole :
    approle.role_name => approle.role_id
  }
}
