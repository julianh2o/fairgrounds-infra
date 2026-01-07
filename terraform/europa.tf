module "europa" {
  source = "./modules/docker-vm"

  hostname    = "europa"
  description = "Docker Services VM"
  node_name   = var.proxmox_node_name
  vm_id       = 102

  # Resources
  cpu_cores    = 1
  memory_mb    = 8192
  disk_size_gb = 50

  network_bridge = "vmbr0"
  ip_address     = "192.168.0.222/24"
}

output "europa_vm_id" {
  value       = module.europa.vm_id
}

output "europa_vm_name" {
  value       = module.europa.vm_name
}