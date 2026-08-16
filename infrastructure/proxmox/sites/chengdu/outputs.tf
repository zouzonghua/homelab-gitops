output "k3s_servers" {
  description = "Created Chengdu K3s server VM identifiers and addresses."
  value = {
    for key, server in local.k3s_servers : key => {
      vm_id   = server.vm_id
      name    = server.name
      address = server.address
    }
  }
}
