# Terraform Configuration for Proxmox

Other VM Names: (sea nymphs) Thebe, Electra, Galatea, Thetis, Styx, Clymene

This directory contains Terraform configurations for managing Proxmox VMs.

## Prerequisites

1. **Proxmox API Token**: Already configured in Ansible vault
2. **SSH Public Key**: Located at `../secrets/id_ed25519.pub`
3. **Terraform**: Install from https://www.terraform.io/downloads

## Configuration

### Variables

The following variables are auto-generated from Ansible vault:
- `proxmox_api_url` - Proxmox API endpoint
- `proxmox_api_token_id` - API token ID
- `proxmox_api_token_secret` - API token secret

Additional variables you may need to customize in `terraform.tfvars`:
- `proxmox_node_name` - Default: `"pve"` (your Proxmox node name)
- `proxmox_storage` - Default: `"local-lvm"` (storage pool for disks)

### Regenerate terraform.tfvars

If you need to regenerate the variables file from vault:

```bash
ansible-playbook playbooks/setup/setup_terraform_vars.yaml
```

## Current Containers

### galene (LXC)
- **Purpose**: Docker service host
- **Type**: LXC Container (privileged for Docker support)
- **OS**: Ubuntu 24.04 LTS
- **Resources**: 4 CPU, 4GB RAM, 40GB disk
- **Container ID**: 200
- **Network**: DHCP on vmbr0
- **File**: `lxc-galene.tf`
- **Features**: Nesting enabled for Docker, auto-start on boot

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Check Your Proxmox Configuration

Before applying, verify these settings match your Proxmox setup:

1. **Node name**: Check what your Proxmox node is called:
   - Login to Proxmox web UI
   - The node name is shown in the left sidebar (likely "pve")

2. **Storage pool**: Check available storage:
   - In Proxmox: Datacenter → Storage
   - Common options: `local-lvm`, `local`, or custom storage names

3. **Network bridge**: Check network configuration:
   - In Proxmox: Node → System → Network
   - Default is usually `vmbr0`

If your settings differ from defaults, add them to `terraform.tfvars`:

```hcl
proxmox_node_name = "your-node-name"
proxmox_storage   = "your-storage-pool"
```

### Plan Changes

See what Terraform will create:

```bash
terraform plan
```

### Apply Changes

Create the VM(s):

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Destroy VMs

Remove managed VMs:

```bash
terraform destroy
```

## After Container/VM Creation

Once the container is created:

1. **Get IP address**: Check Proxmox console or DHCP leases
2. **SSH access**: `ssh root@<container-ip>` (uses your SSH key)
3. **Install Docker** (for LXC containers):
   ```bash
   apt update && apt install -y docker.io docker-compose-plugin
   systemctl enable docker
   systemctl start docker
   ```
4. **Create service user** (optional): Create a non-root user for Ansible
5. **Add to Ansible inventory**: Add the container to `inventory.yaml`
6. **Configure with Ansible**: Deploy services using your Ansible playbooks

### LXC vs VM Considerations

**LXC Containers** (like galene):
- Lighter weight, faster startup
- Share kernel with host (less isolation)
- Must be privileged for Docker support
- More efficient resource usage

**VMs**:
- Full hardware virtualization
- Complete isolation
- Can run any OS
- Slightly more overhead

## Customization

### Static IP Instead of DHCP

Edit the VM's `initialization.ip_config` block:

```hcl
ip_config {
  ipv4 {
    address = "192.168.0.210/23"  # Static IP in your /23 network
    gateway = "192.168.0.1"
  }
}
```

### Different Resources

Adjust the `cpu` and `memory` blocks:

```hcl
cpu {
  cores = 8  # More CPU
}

memory {
  dedicated = 8192  # 8GB RAM
}
```

### Different Disk Size

Change the `disk.size` parameter:

```hcl
disk {
  size = 80  # 80GB disk
}
```

## Troubleshooting

### "Resource already exists"

If a VM with ID 200 already exists, change the `vm_id` in the VM configuration.

### Storage errors

Verify your storage pool name matches what's in Proxmox. Common names:
- `local-lvm` - LVM storage
- `local` - Directory storage
- Custom storage pool names

### Network issues

Ensure `vmbr0` exists or change to your network bridge name.

### Cloud image download fails

The Ubuntu cloud image is downloaded automatically. If it fails:
- Check internet connectivity from Proxmox
- Verify storage has enough space
- Check Proxmox logs: `/var/log/pve/tasks/`
