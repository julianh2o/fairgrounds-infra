# fairgrounds-infra
Infrastructure for the fairgrounds

# Managing Secrets

Secrets are stored in `secrets.yml` encrypted with ansible-vault.

```bash
# Edit secrets
ansible-vault edit secrets.yml

# View secrets
ansible-vault view secrets.yml

# Generate a random password
openssl rand -base64 32

# Add a new secret with a random password
ansible-vault decrypt secrets.yml && echo "my_secret: $(openssl rand -base64 32)" >> secrets.yml && ansible-vault encrypt secrets.yml
```

Required secrets:
- `kopia_server_password` - Kopia web UI password
- `kopia_repository_password` - Kopia repository encryption password

# TODO
* create Calcifer VM for home assistant
* more work on grafana dashboards
* create a good CPU/memory chart for the VM children under the host parent.. These should be colocated and intuitive to show where the resources are going.
* We can do this CPU/memory chart for both proxmox and truenas
* It would be great to have a similar network chart that we can weigh against our Gigabit connection. eg..  a way to see how much of our total bandwidth is being used.
* install uptime kuma: https://github.com/louislam/uptime-kuma
* add server and service status to home assistant dashboard
* Decomission Melinoe
* Move plex to Ceto
* Move ollama to ceto
* Move speaches to Ceto (also.. do we still want it?)
* Move ollama to Ceto
* Move homeassistant to a new proxmox VM
* decommmission truenas version of homeassistant
* create local database server


# GPU Passthrough Setup Instructions
See: https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/

# Update (/etc/default/grub)
`GRUB_CMDLINE_LINUX_DEFAULT="quiet"`

`GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"`
to
`GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"`

`update-grub`

# Create (/etc/modules-load.d/05-vfio.conf)
```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

# IOMMU Interrupt Mapping
`echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf`
`echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf`

# Blacklist Drivers
`echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf`
`echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf`
`echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf`

root@njord:/etc/modules-load.d# lspci -n -s 0b:00.0
0b:00.0 0300: 10de:1e84 (rev a1)
root@njord:/etc/modules-load.d# lspci -n -s 0b:00.1
0b:00.1 0403: 10de:10f8 (rev a1)

echo "options vfio-pci ids=10de:1e84,10de:10f8 disable_vga=1"> /etc/modprobe.d/vfio.conf
