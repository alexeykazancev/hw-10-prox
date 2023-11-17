resource "proxmox_vm_qemu" "vm" {
  count       = var.vm_count
  name        = "${var.vm_prefix}-${count.index}"
  desc        = "VM ${var.vm_prefix}-${count.index}"
  target_node = var.pm_target_node_name

  kvm = true

  clone    = var.vm_template
  cpu      = "host"
  numa     = false
  cores    = 2
  sockets  = 1
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  network {
    #id        = 0
    model     = "virtio"
    bridge    = var.vm_bridge
    firewall  = false
    link_down = false
  }

  disk {
      #id           = 1 # 0 - already exists in template OS
      size         = "10G"
      type         = "virtio"
      storage      = "local-lvm"
      storage_type = "lvmthin"
      iothread     = 1
      discard      = "ignore"
  }

  force_create = false
  full_clone   = true

  os_type = "cloud-init"
  ciuser  = var.ci_user
  sshkeys = file(var.ci_ssh_public_keys_file)

  nameserver   = var.vm_ip_dns
  searchdomain = var.vm_searchdomain
  ipconfig0    = "ip=${var.vm_ip_network}${count.index + var.vm_ip_network_start}/${var.vm_ip_cidr},gw=${var.vm_ip_gateway}"

  agent   = 1
  balloon = 0
  onboot  = false

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}