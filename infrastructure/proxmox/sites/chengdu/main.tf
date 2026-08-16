locals {
  host_inventory    = yamldecode(file("${path.root}/../../../../inventory/hosts.yaml"))
  service_inventory = yamldecode(file("${path.root}/../../../../inventory/services.yaml"))

  k3s_servers = {
    for host in local.host_inventory.hosts : host.name => {
      vm_id         = host.vm_id
      name          = host.name
      address       = "${host.address}/24"
      startup_order = host.startup_order
    }
    if host.site == "chengdu" && host.role == "k3s-server"
  }

  k3s_api_vip = one([
    for service in local.service_inventory.services : service.address
    if service.name == "chengdu-k3s-api"
  ])
}

resource "proxmox_download_file" "debian_cloud_image" {
  content_type       = "import"
  datastore_id       = var.template_storage
  node_name          = var.node_name
  file_name          = "debian-13-genericcloud-amd64-20260810-2566.qcow2"
  url                = var.debian_image_url
  checksum           = var.debian_image_checksum
  checksum_algorithm = "sha512"
  overwrite          = false
}

resource "proxmox_virtual_environment_vm" "debian_template" {
  name        = "tpl-vm-debian"
  description = "Debian 13 cloud-init template managed by OpenTofu."

  node_name = var.node_name
  vm_id     = 400
  template  = true
  started   = false

  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = var.template_storage
    import_from  = proxmox_download_file.debian_cloud_image.id
    interface    = "scsi0"
    size         = 8
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  initialization {
    datastore_id = var.template_storage
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.network_vlan_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  delete_unreferenced_disks_on_destroy = false
  purge_on_destroy                     = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "k3s_server" {
  for_each = local.k3s_servers

  name        = each.value.name
  description = "Chengdu K3s server managed by OpenTofu."

  node_name = var.node_name
  vm_id     = each.value.vm_id
  on_boot   = true
  started   = true

  scsi_hardware = "virtio-scsi-single"

  clone {
    datastore_id = var.vm_storage
    full         = true
    node_name    = var.node_name
    vm_id        = proxmox_virtual_environment_vm.debian_template.vm_id
  }

  agent {
    enabled = true
  }

  startup {
    order      = tostring(each.value.startup_order)
    up_delay   = "30"
    down_delay = "30"
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = var.vm_storage
    interface    = "scsi0"
    size         = 20
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  initialization {
    datastore_id = var.vm_storage

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = each.value.address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [trimspace(var.ssh_public_key)]
      username = "ops"
    }
  }

  network_device {
    bridge   = var.network_bridge
    firewall = true
    model    = "virtio"
    vlan_id  = var.network_vlan_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  delete_unreferenced_disks_on_destroy = false
  purge_on_destroy                     = false
  stop_on_destroy                      = true

  lifecycle {
    prevent_destroy = true
  }
}
