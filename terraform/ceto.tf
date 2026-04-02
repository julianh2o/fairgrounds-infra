module "ceto" {
  source = "./modules/docker-vm"

  hostname    = "ceto"
  description = "Docker Services VM"
  node_name   = var.proxmox_node_name
  vm_id       = 100
  machine     = "q35"
  bios        = "ovmf"

  # Resources
  cpu_cores    = 2
  memory_mb    = 16384
  disk_size_gb = 50

  network_bridge = "vmbr0"
  ip_address     = "10.10.0.10/24"
}

output "ceto_vm_id" {
  value       = module.ceto.vm_id
}

output "ceto_vm_name" {
  value       = module.ceto.vm_name
}
