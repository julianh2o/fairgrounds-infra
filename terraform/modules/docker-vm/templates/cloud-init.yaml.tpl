#cloud-config
users:
  - name: user
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

ssh_pwauth: true

chpasswd:
  list: |
    user:lemmings
  expire: false

runcmd:
  - systemctl restart ssh

power_state:
  mode: reboot
