module "arethusa" {
  source = "./modules/docker-vm"

  hostname    = "arethusa"
  description = "Development Sandbox"
  node_name   = var.proxmox_node_name
  vm_id       = 104

  # Resources
  cpu_cores    = 2
  memory_mb    = 8192
  disk_size_gb = 200

  network_bridge = "vmbr0"
  ip_address     = "10.10.0.14/24"
}

output "arethusa_vm_id" {
  value       = module.arethusa.vm_id
}

output "arethusa_vm_name" {
  value       = module.arethusa.vm_name
}
