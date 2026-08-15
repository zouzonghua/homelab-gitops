variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint."
  type        = string
  default     = "https://10.10.10.2:8006/"
}

variable "proxmox_insecure" {
  description = "Allow the self-signed certificate currently used by the PVE API."
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Target Proxmox node name."
  type        = string
  default     = "pve"
}

variable "vm_storage" {
  description = "Temporary datastore for the Debian template and K3s VM disks."
  type        = string
  default     = "pve_share"
}

variable "network_bridge" {
  description = "VLAN-aware Proxmox bridge connected to the LAN trunk."
  type        = string
  default     = "vmbr1"
}

variable "network_vlan_id" {
  description = "Infra VLAN used by the K3s nodes."
  type        = number
  default     = 10
}

variable "gateway" {
  description = "IPv4 gateway for the Infra VLAN."
  type        = string
  default     = "10.10.10.1"
}

variable "dns_servers" {
  description = "DNS servers written by cloud-init."
  type        = list(string)
  default     = ["10.10.10.1"]
}

variable "ssh_public_key" {
  description = "SSH public key installed for the Debian cloud-init user."
  type        = string

  validation {
    condition     = can(regex("^ssh-(ed25519|rsa) ", trimspace(var.ssh_public_key)))
    error_message = "ssh_public_key must be an OpenSSH ed25519 or RSA public key."
  }
}

variable "debian_image_url" {
  description = "Official Debian 13 generic cloud image."
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/20260810-2566/debian-13-genericcloud-amd64-20260810-2566.qcow2"
}

variable "debian_image_checksum" {
  description = "SHA-512 checksum published by Debian for the pinned cloud image."
  type        = string
  default     = "0ce1f1d675733027d3e17a4665cb95e1d7173bdf67fb8a87ff822ff5ee025bc2a90ecb270465ef395755e41c868b40072eb9ac493810196d9cf68f941afb93dc"

  validation {
    condition     = can(regex("^[0-9a-f]{128}$", var.debian_image_checksum))
    error_message = "debian_image_checksum must be a SHA-512 hexadecimal digest."
  }
}
