resource "proxmox_virtual_environment_container" "galene" {
  description = "Galene - LXC Container"
  node_name   = var.proxmox_node_name
  vm_id       = 200

  # Container startup configuration
  start_on_boot = true

  # Operating system template
  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  # CPU allocation
  cpu {
    cores = 4
  }

  # Memory allocation
  memory {
    dedicated = 4096  # 4GB
    swap      = 512   # 512MB swap
  }

  # Root disk
  disk {
    datastore_id = var.proxmox_storage
    size         = 40  # 40GB
  }

  # Network configuration - DHCP
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  # Initialize with SSH key
  initialization {
    hostname = "galene"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        trimspace(file("${path.module}/../secrets/id_ed25519.pub"))
      ]
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to the template as it might be upgraded in Proxmox
      operating_system[0].template_file_id,
    ]
  }
}

# Output the container ID for reference
output "galene_container_id" {
  value       = proxmox_virtual_environment_container.galene.id
  description = "The ID of the galene LXC container"
}