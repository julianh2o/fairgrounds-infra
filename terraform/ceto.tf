module "ceto" {
  source = "./modules/docker-vm"

  hostname    = "ceto"
  description = "Docker Services VM"
  node_name   = var.proxmox_node_name
  vm_id       = 100
  machine     = "q35"
  bios        = "ovmf"

  vga_type = "none"

  # PCI passthrough - NVIDIA RTX 2070 SUPER has 4 functions that must all be passed through
  # Ensure hardware mapping "gpu-nvidia" includes all 4 functions: 0b:00.0-0b:00.3
  # Or create separate mappings for each function
  hostpci_devices = [
    {
      device  = "hostpci0"
      mapping = "gpu-nvidia"  # Should include 0b:00.0, 0b:00.1, 0b:00.2, 0b:00.3
      pcie    = true
      rombar  = true
      xvga    = false
    }
  ]

  # Resources
  cpu_cores    = 2
  cpu_type     = "host"  # Required for GPU passthrough
  memory_mb    = 8192
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
