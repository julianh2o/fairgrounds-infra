#cloud-config
users:
  - name: myuser
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

ssh_pwauth: True

chpasswd:
  list: |
    myuser:lemmings
  expire: false
