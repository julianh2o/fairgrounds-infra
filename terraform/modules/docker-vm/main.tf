terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.71"
    }
  }
}

# Cloud-init user data to install and enable SSH
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    data = <<-EOF
    packages:
      - openssh-server
      - qemu-guest-agent

    users:
      - name: root
        ssh_authorized_keys:
          - ${trimspace(file("${path.module}/../../../secrets/id_ed25519.pub"))}

    write_files:
      - path: /etc/ssh/sshd_config.d/99-custom.conf
        content: |
          ListenAddress 0.0.0.0
          PasswordAuthentication no
          PubkeyAuthentication yes
          PermitRootLogin prohibit-password
        permissions: '0644'

    runcmd:
      - systemctl enable ssh
      - systemctl restart ssh
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent

    package_update: true
    package_upgrade: false
    EOF

    file_name = "${var.hostname}-cloud-init.yaml"
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

  # Prevent replacement when cloud-init config changes
  # (cloud-init only runs at VM creation, so changes don't affect running VMs)
  lifecycle {
    ignore_changes = [
      initialization,
    ]
  }

  # CPU configuration
  cpu {
    cores = var.cpu_cores
  }

  # Memory configuration
  memory {
    dedicated = var.memory_mb
  }

  # Network device
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
  }

  # Cloud-init configuration
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