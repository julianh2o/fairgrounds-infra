
module "daphne" {
  source = "./modules/docker-vm"

  hostname    = "daphne"
  description = "Development Sandbox"
  node_name   = var.proxmox_node_name
  vm_id       = 103

  # Resources
  cpu_cores    = 1
  memory_mb    = 4096
  disk_size_gb = 50

  network_bridge = "vmbr0"
  ip_address     = "192.168.0.13/24"
}

output "daphne_vm_id" {
  value       = module.daphne.vm_id
}

output "daphne_vm_name" {
  value       = module.daphne.vm_name
}
