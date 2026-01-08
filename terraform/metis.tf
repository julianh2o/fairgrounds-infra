module "metis" {
  source = "./modules/docker-vm"

  hostname    = "metis"
  description = "Docker Services VM"
  node_name   = var.proxmox_node_name
  vm_id       = 101

  # Resources
  cpu_cores    = 1
  memory_mb    = 8192
  disk_size_gb = 50

  network_bridge = "vmbr0"
  ip_address     = "192.168.0.11/24"
}

output "metis_vm_id" {
  value       = module.metis.vm_id
}

output "metis_vm_name" {
  value       = module.metis.vm_name
}