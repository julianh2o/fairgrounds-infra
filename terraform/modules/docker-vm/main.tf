terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.71"
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
      ssh_public_key = trimspace(file("${path.root}/../secrets/id_ed25519.pub"))
    })

    file_name = "cloud-init-${var.hostname}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.hostname
  description = var.description
  node_name   = var.node_name
  vm_id       = var.vm_id

  # Clone from template
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  on_boot = var.start_on_boot

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
  }

  network_device {
    bridge = var.network_bridge
  }

  # Resize disk if needed
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  # Enable QEMU agent
  agent {
    enabled = true
    timeout = "1s"  # Short timeout to prevent hanging
  }

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.ip_gateway
      }
    }
  }
}