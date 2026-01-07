module "ceto" {
  source = "./modules/docker-vm"

  hostname    = "ceto"
  description = "Docker Services VM"
  node_name   = var.proxmox_node_name
  vm_id       = 100

  # Resources
  cpu_cores    = 2
  memory_mb    = 8192
  disk_size_gb = 50

  # Network - using DHCP by default
  network_bridge = "vmbr0"
  ip_address     = "192.168.0.220/24"
}

# Output the VM information
output "ceto_vm_id" {
  value       = module.ceto.vm_id
  description = "The ID of the ceto VM"
}

output "ceto_vm_name" {
  value       = module.ceto.vm_name
  description = "The name of the ceto VM"
}